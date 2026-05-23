# frozen_string_literal: true

require "test_helper"

class SubscriptionPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  test "unsubscribe_by_seller? — permits owner, admin, support when subscription is for seller's product" do
    [:named_seller, :admin_for_named_seller, :support_for_named_seller].each do |role|
      assert_policy_permits SubscriptionPolicy,
                            subscriptions(:named_seller_product_subscription),
                            role, :unsubscribe_by_seller?
    end
  end

  test "unsubscribe_by_seller? — denies accountant and marketing" do
    [:accountant_for_named_seller, :marketing_for_named_seller].each do |role|
      refute_policy_permits SubscriptionPolicy,
                            subscriptions(:named_seller_product_subscription),
                            role, :unsubscribe_by_seller?
    end
  end

  test "unsubscribe_by_seller? — denies owner when subscription belongs to another seller's product" do
    refute_policy_permits SubscriptionPolicy,
                          subscriptions(:basic_user_product_subscription),
                          :named_seller, :unsubscribe_by_seller?
  end
end
