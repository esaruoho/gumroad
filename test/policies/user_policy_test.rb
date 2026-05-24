# frozen_string_literal: true

require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  # deactivate? — owner only
  test "deactivate? grants access to owner" do
    assert_policy_permits UserPolicy, users(:named_seller), :named_seller, :deactivate?
  end

  test "deactivate? denies access to accountant" do
    refute_policy_permits UserPolicy, users(:named_seller), :accountant_for_named_seller, :deactivate?
  end

  test "deactivate? denies access to admin" do
    refute_policy_permits UserPolicy, users(:named_seller), :admin_for_named_seller, :deactivate?
  end

  test "deactivate? denies access to marketing" do
    refute_policy_permits UserPolicy, users(:named_seller), :marketing_for_named_seller, :deactivate?
  end

  test "deactivate? denies access to support" do
    refute_policy_permits UserPolicy, users(:named_seller), :support_for_named_seller, :deactivate?
  end

  # generate_product_details_with_ai? branches.
  # All branches funnel through User#eligible_for_ai_product_generation?; we
  # stub that directly to keep the policy test focused on the policy logic
  # rather than ES-backed sales aggregations / Flipper state.
  test "generate_product_details_with_ai? denies when seller is ineligible" do
    seller = users(:named_seller)
    seller.stub(:eligible_for_ai_product_generation?, false) do
      refute_policy_permits UserPolicy, seller, :named_seller, :generate_product_details_with_ai?
    end
  end

  test "generate_product_details_with_ai? grants access to owner when eligible" do
    seller = users(:named_seller)
    seller.stub(:eligible_for_ai_product_generation?, true) do
      assert_policy_permits UserPolicy, seller, :named_seller, :generate_product_details_with_ai?
    end
  end

  test "generate_product_details_with_ai? denies accountant when eligible" do
    seller = users(:named_seller)
    seller.stub(:eligible_for_ai_product_generation?, true) do
      refute_policy_permits UserPolicy, seller, :accountant_for_named_seller, :generate_product_details_with_ai?
    end
  end

  test "generate_product_details_with_ai? grants admin when eligible" do
    seller = users(:named_seller)
    seller.stub(:eligible_for_ai_product_generation?, true) do
      assert_policy_permits UserPolicy, seller, :admin_for_named_seller, :generate_product_details_with_ai?
    end
  end

  test "generate_product_details_with_ai? grants marketing when eligible" do
    seller = users(:named_seller)
    seller.stub(:eligible_for_ai_product_generation?, true) do
      assert_policy_permits UserPolicy, seller, :marketing_for_named_seller, :generate_product_details_with_ai?
    end
  end

  test "generate_product_details_with_ai? denies support when eligible" do
    seller = users(:named_seller)
    seller.stub(:eligible_for_ai_product_generation?, true) do
      refute_policy_permits UserPolicy, seller, :support_for_named_seller, :generate_product_details_with_ai?
    end
  end
end
