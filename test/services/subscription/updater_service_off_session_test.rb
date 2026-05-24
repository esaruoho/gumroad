# frozen_string_literal: true

require "test_helper"

class Subscription::UpdaterServiceOffSessionTest < ActiveSupport::TestCase
  FakeCard = Struct.new(:requires_mandate?)
  FakeErrors = Struct.new(:full_messages)

  FakePurchase = Struct.new(:errors, :error_code, :charge_intent, :external_id, keyword_init: true) do
    def successful? = true
    def test_successful? = false
    def in_progress? = false
  end

  test "#charge_user! passes off_session true when stripe_setup_intent_id is present" do
    captured_args = charge_user!(card_requires_mandate: true, extra_params: { stripe_setup_intent_id: "seti_123" })

    assert_equal true, captured_args[:off_session]
  end

  test "#charge_user! does not merge setup_future_charges when stripe_setup_intent_id is present" do
    captured_args = charge_user!(card_requires_mandate: true, extra_params: { stripe_setup_intent_id: "seti_123" })

    assert_not captured_args[:override_params].key?(:setup_future_charges)
  end

  test "#charge_user! passes off_session false when no setup intent exists and the card requires mandate" do
    captured_args = charge_user!(card_requires_mandate: true)

    assert_equal false, captured_args[:off_session]
  end

  test "#charge_user! merges setup_future_charges when no setup intent exists and the card requires mandate" do
    captured_args = charge_user!(card_requires_mandate: true)

    assert_equal true, captured_args[:override_params][:setup_future_charges]
  end

  test "#charge_user! passes off_session true when no setup intent exists and the card does not require mandate" do
    captured_args = charge_user!(card_requires_mandate: false)

    assert_equal true, captured_args[:off_session]
  end

  private
    def charge_user!(card_requires_mandate:, extra_params: {})
      subscription = subscriptions(:magic_link_subscription)
      captured_args = nil
      successful_purchase = FakePurchase.new(
        errors: FakeErrors.new([]),
        error_code: nil,
        charge_intent: nil,
        external_id: "ext_123"
      )

      subscription.define_singleton_method(:credit_card_to_charge) { FakeCard.new(card_requires_mandate) }
      subscription.define_singleton_method(:current_subscription_price_cents) { |authenticated_offer_code_buyer: nil| 100 }
      subscription.define_singleton_method(:charge!) do |**kwargs|
        captured_args = kwargs
        successful_purchase
      end

      updater = Subscription::UpdaterService.new(
        subscription:,
        params: {
          use_existing_card: true,
        }.merge(extra_params),
        logged_in_user: users(:magic_link_user),
        gumroad_guid: "test-guid",
        remote_ip: "127.0.0.1"
      )
      updater.original_purchase = purchases(:magic_link_membership_purchase)
      updater.original_price = prices(:magic_link_product_price)
      updater.prorated_discount_price_cents = 0
      updater.overdue_for_charge = true
      updater.is_resubscribing = true

      updater.send(:charge_user!)

      captured_args
    end
end
