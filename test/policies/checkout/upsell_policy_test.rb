# frozen_string_literal: true

require "test_helper"

class Checkout::UpsellPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  INDEX_ACTIONS = %i[index? paged? cart_item? statistics?].freeze
  CREATE_ACTIONS = %i[create?].freeze
  WRITE_ACTIONS = %i[update? destroy? pause? unpause?].freeze

  test "index? paged? cart_item? statistics? — permits owner and all 4 roles" do
    [:named_seller, :accountant_for_named_seller, :admin_for_named_seller,
     :marketing_for_named_seller, :support_for_named_seller].each do |role|
      assert_policy_permits Checkout::UpsellPolicy, Upsell, role, *INDEX_ACTIONS
    end
  end

  test "create? — permits owner, admin, marketing" do
    [:named_seller, :admin_for_named_seller, :marketing_for_named_seller].each do |role|
      assert_policy_permits Checkout::UpsellPolicy, Upsell, role, *CREATE_ACTIONS
    end
  end

  test "create? — denies accountant and support" do
    [:accountant_for_named_seller, :support_for_named_seller].each do |role|
      refute_policy_permits Checkout::UpsellPolicy, Upsell, role, *CREATE_ACTIONS
    end
  end

  test "update? destroy? pause? unpause? on own upsell — permits owner, admin, marketing" do
    [:named_seller, :admin_for_named_seller, :marketing_for_named_seller].each do |role|
      assert_policy_permits Checkout::UpsellPolicy,
                            upsells(:named_seller_upsell), role, *WRITE_ACTIONS
    end
  end

  test "update? destroy? pause? unpause? on own upsell — denies accountant and support" do
    [:accountant_for_named_seller, :support_for_named_seller].each do |role|
      refute_policy_permits Checkout::UpsellPolicy,
                            upsells(:named_seller_upsell), role, *WRITE_ACTIONS
    end
  end

  test "update? destroy? pause? unpause? on another seller's upsell — denies all roles" do
    [:named_seller, :accountant_for_named_seller, :admin_for_named_seller,
     :marketing_for_named_seller, :support_for_named_seller].each do |role|
      refute_policy_permits Checkout::UpsellPolicy,
                            upsells(:basic_user_upsell), role, *WRITE_ACTIONS
    end
  end
end
