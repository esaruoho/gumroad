# frozen_string_literal: true

require "test_helper"

class Checkout::OfferCodePolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  INDEX_ACTIONS = %i[index? paged? statistics?].freeze
  CREATE_ACTIONS = %i[create?].freeze
  WRITE_ACTIONS = %i[update? destroy?].freeze

  # index/paged/statistics — owner + all 4 roles permitted
  test "index? paged? statistics? — permits owner and all 4 roles" do
    [:named_seller, :accountant_for_named_seller, :admin_for_named_seller,
     :marketing_for_named_seller, :support_for_named_seller].each do |role|
      assert_policy_permits Checkout::OfferCodePolicy, OfferCode, role, *INDEX_ACTIONS
    end
  end

  # create? — owner, admin, marketing only
  test "create? — permits owner, admin, marketing" do
    [:named_seller, :admin_for_named_seller, :marketing_for_named_seller].each do |role|
      assert_policy_permits Checkout::OfferCodePolicy, OfferCode, role, *CREATE_ACTIONS
    end
  end

  test "create? — denies accountant and support" do
    [:accountant_for_named_seller, :support_for_named_seller].each do |role|
      refute_policy_permits Checkout::OfferCodePolicy, OfferCode, role, *CREATE_ACTIONS
    end
  end

  # update?/destroy? on own offer_code
  test "update? destroy? on own offer code — permits owner, admin, marketing" do
    [:named_seller, :admin_for_named_seller, :marketing_for_named_seller].each do |role|
      assert_policy_permits Checkout::OfferCodePolicy,
                            offer_codes(:named_seller_offer_code), role, *WRITE_ACTIONS
    end
  end

  test "update? destroy? on own offer code — denies accountant and support" do
    [:accountant_for_named_seller, :support_for_named_seller].each do |role|
      refute_policy_permits Checkout::OfferCodePolicy,
                            offer_codes(:named_seller_offer_code), role, *WRITE_ACTIONS
    end
  end

  # update?/destroy? on another seller's offer_code — all denied
  test "update? destroy? on another seller's offer code — denies all roles" do
    [:named_seller, :accountant_for_named_seller, :admin_for_named_seller,
     :marketing_for_named_seller, :support_for_named_seller].each do |role|
      refute_policy_permits Checkout::OfferCodePolicy,
                            offer_codes(:basic_user_offer_code), role, *WRITE_ACTIONS
    end
  end
end
