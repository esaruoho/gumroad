# frozen_string_literal: true

require "test_helper"

class WishlistProductPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[index? destroy?].freeze

  test "grants access to owner" do
    assert_policy_permits WishlistProductPolicy, wishlist_products(:named_seller_wishlist_product), :named_seller, *ACTIONS
  end

  test "denies access to accountant" do
    refute_policy_permits WishlistProductPolicy, wishlist_products(:named_seller_wishlist_product), :accountant_for_named_seller, *ACTIONS
  end

  test "denies access to admin" do
    refute_policy_permits WishlistProductPolicy, wishlist_products(:named_seller_wishlist_product), :admin_for_named_seller, *ACTIONS
  end

  test "denies access to marketing" do
    refute_policy_permits WishlistProductPolicy, wishlist_products(:named_seller_wishlist_product), :marketing_for_named_seller, *ACTIONS
  end

  test "denies access to support" do
    refute_policy_permits WishlistProductPolicy, wishlist_products(:named_seller_wishlist_product), :support_for_named_seller, *ACTIONS
  end

  test "destroy? denies access to another user's wishlist product" do
    refute_policy_permits WishlistProductPolicy, wishlist_products(:basic_user_wishlist_product), :named_seller, :destroy?
  end
end
