# frozen_string_literal: true

require "test_helper"

class Subscription::RestartableTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @product = links(:restartable_membership_product)
    @regular_product = links(:restartable_regular_product)
    @buyer = users(:restartable_buyer)
  end

  # Build a subscription + original purchase pair, bypassing model validations
  # AND before_create callbacks (which require payment options / sellable product
  # state we don't model in fixtures).
  def create_subscription_with_purchase(product:, purchaser:, created_at: Time.current, **attrs)
    now = Time.current
    sub_attrs = {
      link_id: product.id,
      user_id: purchaser.id,
      seller_id: product.user_id,
      created_at: created_at,
      updated_at: now,
      flags: 0,
    }.merge(attrs)
    Subscription.insert!(sub_attrs)
    sub = Subscription.where(link_id: product.id, user_id: purchaser.id).order(:id).last

    Purchase.insert!({
      link_id: product.id,
      seller_id: product.user_id,
      purchaser_id: purchaser.id,
      email: purchaser.email,
      subscription_id: sub.id,
      price_cents: product.price_cents,
      total_transaction_cents: product.price_cents,
      displayed_price_cents: product.price_cents,
      displayed_price_currency_type: "usd",
      purchase_state: "successful",
      succeeded_at: now,
      created_at: now,
      updated_at: now,
      # is_original_subscription_purchase = flag bit 3 (= 4)
      flags: 4,
    })

    sub
  end

  # ---- restartable_for_product_and_buyer ----

  test ".restartable_for_product_and_buyer returns nil when product is not a membership" do
    assert_nil Subscription.restartable_for_product_and_buyer(product: @regular_product, buyer: @buyer)
  end

  test ".restartable_for_product_and_buyer returns the subscription when cancelled by buyer" do
    sub = create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      cancelled_at: 1.day.ago, deactivated_at: 1.day.ago,
      flags: 2 # cancelled_by_buyer
    )
    assert_equal sub, Subscription.restartable_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  test ".restartable_for_product_and_buyer returns the subscription when failed" do
    sub = create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      failed_at: 1.day.ago, deactivated_at: 1.day.ago
    )
    assert_equal sub, Subscription.restartable_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  test ".restartable_for_product_and_buyer returns nil when cancelled by admin" do
    create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      cancelled_at: 1.day.ago, deactivated_at: 1.day.ago,
      flags: 4 # cancelled_by_admin (bit 3 = 4)
    )
    assert_nil Subscription.restartable_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  test ".restartable_for_product_and_buyer returns nil when subscription has ended" do
    create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      ended_at: 1.day.ago, deactivated_at: 1.day.ago
    )
    assert_nil Subscription.restartable_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  test ".restartable_for_product_and_buyer returns nil when subscription is active" do
    create_subscription_with_purchase(product: @product, purchaser: @buyer)
    assert_nil Subscription.restartable_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  test ".restartable_for_product_and_buyer returns nil for a deactivated test subscription" do
    create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      cancelled_at: 1.day.ago, deactivated_at: 1.day.ago,
      flags: 3 # is_test_subscription (1) + cancelled_by_buyer (2)
    )
    assert_nil Subscription.restartable_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  test ".restartable_for_product_and_buyer returns nil when user has no subscription" do
    assert_nil Subscription.restartable_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  test ".restartable_for_product_and_buyer returns the most recently created subscription" do
    create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      created_at: 2.months.ago,
      cancelled_at: 2.months.ago, deactivated_at: 2.months.ago,
      flags: 2
    )
    newer = create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      created_at: 1.month.ago,
      cancelled_at: 1.day.ago, deactivated_at: 1.day.ago,
      flags: 2
    )
    assert_equal newer, Subscription.restartable_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  # ---- restartable_for_product_and_email ----

  test ".restartable_for_product_and_email returns the subscription matching by email" do
    sub = create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      cancelled_at: 1.day.ago, deactivated_at: 1.day.ago, flags: 2
    )
    assert_equal sub, Subscription.restartable_for_product_and_email(product: @product, email: @buyer.email)
  end

  test ".restartable_for_product_and_email handles email case insensitivity" do
    sub = create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      cancelled_at: 1.day.ago, deactivated_at: 1.day.ago, flags: 2
    )
    assert_equal sub, Subscription.restartable_for_product_and_email(product: @product, email: @buyer.email.upcase)
  end

  test ".restartable_for_product_and_email returns nil for a deactivated test subscription" do
    create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      cancelled_at: 1.day.ago, deactivated_at: 1.day.ago,
      flags: 3
    )
    assert_nil Subscription.restartable_for_product_and_email(product: @product, email: @buyer.email)
  end

  # ---- active_for_product_and_buyer ----

  test ".active_for_product_and_buyer returns nil for non-membership product" do
    assert_nil Subscription.active_for_product_and_buyer(product: @regular_product, buyer: @buyer)
  end

  test ".active_for_product_and_buyer returns the subscription when active" do
    sub = create_subscription_with_purchase(product: @product, purchaser: @buyer)
    assert_equal sub, Subscription.active_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  test ".active_for_product_and_buyer returns the subscription when pending cancellation" do
    sub = create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      cancelled_at: 1.month.from_now, flags: 2
    )
    assert_equal sub, Subscription.active_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  test ".active_for_product_and_buyer returns nil when cancelled" do
    create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      cancelled_at: 1.day.ago, deactivated_at: 1.day.ago, flags: 2
    )
    assert_nil Subscription.active_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  test ".active_for_product_and_buyer returns nil when failed" do
    create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      failed_at: 1.day.ago, deactivated_at: 1.day.ago
    )
    assert_nil Subscription.active_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  test ".active_for_product_and_buyer returns nil when user has no subscription" do
    assert_nil Subscription.active_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  test ".active_for_product_and_buyer returns nil for a test subscription" do
    create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      flags: 1 # is_test_subscription
    )
    assert_nil Subscription.active_for_product_and_buyer(product: @product, buyer: @buyer)
  end

  # ---- active_for_product_and_email ----

  test ".active_for_product_and_email returns the subscription when active" do
    sub = create_subscription_with_purchase(product: @product, purchaser: @buyer)
    assert_equal sub, Subscription.active_for_product_and_email(product: @product, email: @buyer.email)
  end

  test ".active_for_product_and_email handles email case insensitivity" do
    sub = create_subscription_with_purchase(product: @product, purchaser: @buyer)
    assert_equal sub, Subscription.active_for_product_and_email(product: @product, email: @buyer.email.upcase)
  end

  test ".active_for_product_and_email returns nil for a test subscription" do
    create_subscription_with_purchase(
      product: @product, purchaser: @buyer,
      flags: 1
    )
    assert_nil Subscription.active_for_product_and_email(product: @product, email: @buyer.email)
  end
end
