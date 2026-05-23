# frozen_string_literal: true

require "test_helper"

class WishlistPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[index? update? destroy?].freeze

  test "grants access to owner" do
    assert_policy_permits WishlistPolicy, wishlists(:named_seller_wishlist), :named_seller, *ACTIONS
  end

  test "denies access to accountant" do
    refute_policy_permits WishlistPolicy, wishlists(:named_seller_wishlist), :accountant_for_named_seller, *ACTIONS
  end

  test "denies access to admin" do
    refute_policy_permits WishlistPolicy, wishlists(:named_seller_wishlist), :admin_for_named_seller, *ACTIONS
  end

  test "denies access to marketing" do
    refute_policy_permits WishlistPolicy, wishlists(:named_seller_wishlist), :marketing_for_named_seller, *ACTIONS
  end

  test "denies access to support" do
    refute_policy_permits WishlistPolicy, wishlists(:named_seller_wishlist), :support_for_named_seller, *ACTIONS
  end

  test "denies access to another user's wishlist for update? and destroy?" do
    refute_policy_permits WishlistPolicy, wishlists(:basic_user_wishlist), :named_seller, :update?, :destroy?
  end
end
