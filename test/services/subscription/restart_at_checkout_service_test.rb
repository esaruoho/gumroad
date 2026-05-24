# frozen_string_literal: true

require "test_helper"

class Subscription::RestartAtCheckoutServiceTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @buyer = users(:basic_user)
    @product = links(:named_seller_product)
    @price = prices(:named_seller_product_price)
    @subscription = subscriptions(:deactivated_worker_cancelled_past_subscription)
    @original_purchase = purchases(:deactivated_worker_past_original_purchase)
    @payment_option = payment_options(:deactivated_worker_past_payment_option)
    @browser_guid = SecureRandom.uuid

    @subscription.update_columns(
      link_id: @product.id,
      seller_id: @seller.id,
      user_id: @buyer.id,
      cancelled_at: 1.day.ago,
      deactivated_at: 1.day.ago
    )
    @original_purchase.update_columns(
      link_id: @product.id,
      seller_id: @seller.id,
      purchaser_id: @buyer.id,
      subscription_id: @subscription.id,
      email: @buyer.email,
      price_cents: @product.price_cents,
      displayed_price_cents: @product.price_cents,
      quantity: 1
    )
    @payment_option.update_columns(subscription_id: @subscription.id, price_id: @price.id)
    @original_purchase.variant_attributes.clear
  end

  test "delegates to Subscription::UpdaterService with transformed checkout params" do
    captured_kwargs = nil
    updater = Minitest::Mock.new
    updater.expect(:perform, { success: true, success_message: "Membership restarted" })

    Subscription::UpdaterService.stub(:new, ->(**kwargs) {
      captured_kwargs = kwargs
      updater
    }) do
      result = service.perform
      assert_equal true, result[:success]
    end

    updater.verify
    assert_equal @subscription, captured_kwargs[:subscription]
    assert_equal @buyer, captured_kwargs[:logged_in_user]
    assert_equal @browser_guid, captured_kwargs[:gumroad_guid]
    assert_equal "127.0.0.1", captured_kwargs[:remote_ip]
    assert_equal @price.external_id, captured_kwargs[:params][:price_id]
    assert_equal @product.price_cents, captured_kwargs[:params][:perceived_price_cents]
    assert_equal @product.price_cents, captured_kwargs[:params][:perceived_upgrade_price_cents]
    assert_equal @product.price_cents, captured_kwargs[:params][:price_range]
    assert_equal true, captured_kwargs[:params][:use_existing_card]
  end

  test "transforms checkout params to updater params" do
    transformed_params = service.send(:updater_service_params)

    assert_equal @product.price_cents, transformed_params[:perceived_price_cents]
    assert_equal @product.price_cents, transformed_params[:perceived_upgrade_price_cents]
    assert_equal @product.price_cents, transformed_params[:price_range]
    assert_equal @price.external_id, transformed_params[:price_id]
    assert_equal true, transformed_params[:use_existing_card]
    assert_equal 1, transformed_params[:quantity]
  end

  test "uses buyer identity when defaulting the perceived restart price" do
    params_without_perceived_price = base_params.deep_dup
    params_without_perceived_price[:purchase].delete(:perceived_price_cents)

    @subscription.stub(:current_subscription_price_cents, ->(authenticated_offer_code_buyer:) {
      assert_nil authenticated_offer_code_buyer
      1_000
    }) do
      guest_params = service(params: params_without_perceived_price, buyer: nil).send(:updater_service_params)

      assert_equal 1_000, guest_params[:perceived_price_cents]
    end

    @subscription.stub(:current_subscription_price_cents, ->(authenticated_offer_code_buyer:) {
      assert_equal @buyer, authenticated_offer_code_buyer
      900
    }) do
      buyer_params = service(params: params_without_perceived_price).send(:updater_service_params)

      assert_equal 900, buyer_params[:perceived_price_cents]
    end
  end

  test "treats submitted Stripe payment data as a new card" do
    transformed_params = service(
      params: base_params.merge(
        stripe_payment_method_id: "pm_123",
        stripe_customer_id: "cus_123",
        stripe_setup_intent_id: "seti_123"
      )
    ).send(:updater_service_params)

    assert_equal "pm_123", transformed_params[:stripe_payment_method_id]
    assert_equal "cus_123", transformed_params[:stripe_customer_id]
    assert_equal "seti_123", transformed_params[:stripe_setup_intent_id]
    assert_equal false, transformed_params[:use_existing_card]
  end

  test "uses explicit variants or falls back to the original purchase variants" do
    variant = base_variants(:integrations_test_variant_v1)
    @original_purchase.variant_attributes << variant

    assert_equal [variant.external_id], service.send(:updater_service_params)[:variants]
    assert_equal ["explicit_variant"], service(params: base_params.merge(variants: ["explicit_variant"])).send(:updater_service_params)[:variants]
  end

  test "adapts successful updater result" do
    result = perform_with_updater_result(success: true, success_message: "Membership restarted")

    assert_equal true, result[:success]
    assert_equal true, result[:restarted_subscription]
    assert_equal @subscription, result[:subscription]
    assert_equal "Membership restarted", result[:message]
  end

  test "adapts updater error result" do
    result = perform_with_updater_result(success: false, error_message: "Something went wrong")

    assert_equal false, result[:success]
    assert_equal "Something went wrong", result[:error_message]
  end

  test "includes card-action fields when the updater asks for confirmation" do
    result = perform_with_updater_result(success: true, requires_card_action: true, client_secret: "secret_123")

    assert_equal true, result[:requires_card_action]
    assert_equal "secret_123", result[:client_secret]
  end

  test "passes through a changed recurrence price id" do
    yearly_price = Price.create!(link: @product, recurrence: "yearly", price_cents: 10_000, currency: Currency::USD)
    transformed_params = service(params: base_params.merge(price_id: yearly_price.external_id)).send(:updater_service_params)

    assert_equal yearly_price.external_id, transformed_params[:price_id]
  end

  test "uses submitted quantity or falls back to original purchase quantity" do
    @original_purchase.update_columns(quantity: 3)

    assert_equal 5, service(params: base_params.merge(quantity: "5")).send(:updater_service_params)[:quantity]
    assert_equal 3, service.send(:updater_service_params)[:quantity]
  end

  test "does not include an offer code when no discount code is entered" do
    transformed_params = service.send(:updater_service_params)

    assert_not transformed_params.key?(:offer_code)
    assert_equal false, transformed_params[:clear_discount]
  end

  test "ignores an invalid discount code" do
    transformed_params = service(
      params: base_params.deep_merge(purchase: { discount_code: "NONEXISTENT" })
    ).send(:updater_service_params)

    assert_not transformed_params.key?(:offer_code)
    assert_equal false, transformed_params[:clear_discount]
  end

  private
    def service(params: base_params, buyer: @buyer)
      Subscription::RestartAtCheckoutService.new(
        subscription: @subscription,
        product: @product,
        params:,
        buyer:
      )
    end

    def base_params
      {
        purchase: {
          email: @buyer.email,
          perceived_price_cents: @product.price_cents,
          browser_guid: @browser_guid
        },
        price_id: @price.external_id,
        remote_ip: "127.0.0.1"
      }
    end

    def perform_with_updater_result(updater_result)
      updater = Minitest::Mock.new
      updater.expect(:perform, updater_result)

      result = nil
      Subscription::UpdaterService.stub(:new, ->(**_kwargs) { updater }) do
        result = service.perform
      end
      updater.verify
      result
    end
end
