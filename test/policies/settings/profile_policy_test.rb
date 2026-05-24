# frozen_string_literal: true

require "test_helper"

class Settings::ProfilePolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  SHOW_ACTIONS = %i[show?].freeze
  UPDATE_ACTIONS = %i[update?].freeze
  ADMIN_ONLY_ACTIONS = %i[update_username? manage_social_connections?].freeze

  # show? — open to all roles
  test "show? grants access to owner" do
    assert_policy_permits Settings::ProfilePolicy, users(:named_seller), :named_seller, *SHOW_ACTIONS
  end

  test "show? grants access to accountant" do
    assert_policy_permits Settings::ProfilePolicy, users(:named_seller), :accountant_for_named_seller, *SHOW_ACTIONS
  end

  test "show? grants access to admin" do
    assert_policy_permits Settings::ProfilePolicy, users(:named_seller), :admin_for_named_seller, *SHOW_ACTIONS
  end

  test "show? grants access to marketing" do
    assert_policy_permits Settings::ProfilePolicy, users(:named_seller), :marketing_for_named_seller, *SHOW_ACTIONS
  end

  test "show? grants access to support" do
    assert_policy_permits Settings::ProfilePolicy, users(:named_seller), :support_for_named_seller, *SHOW_ACTIONS
  end

  # update?
  test "update? grants access to owner" do
    assert_policy_permits Settings::ProfilePolicy, users(:named_seller), :named_seller, *UPDATE_ACTIONS
  end

  test "update? denies access to accountant" do
    refute_policy_permits Settings::ProfilePolicy, users(:named_seller), :accountant_for_named_seller, *UPDATE_ACTIONS
  end

  test "update? grants access to admin" do
    assert_policy_permits Settings::ProfilePolicy, users(:named_seller), :admin_for_named_seller, *UPDATE_ACTIONS
  end

  test "update? grants access to marketing" do
    assert_policy_permits Settings::ProfilePolicy, users(:named_seller), :marketing_for_named_seller, *UPDATE_ACTIONS
  end

  test "update? denies access to support" do
    refute_policy_permits Settings::ProfilePolicy, users(:named_seller), :support_for_named_seller, *UPDATE_ACTIONS
  end

  # update_username? / manage_social_connections? — owner-only
  test "owner-only actions grant access to owner" do
    assert_policy_permits Settings::ProfilePolicy, users(:named_seller), :named_seller, *ADMIN_ONLY_ACTIONS
  end

  test "owner-only actions deny accountant" do
    refute_policy_permits Settings::ProfilePolicy, users(:named_seller), :accountant_for_named_seller, *ADMIN_ONLY_ACTIONS
  end

  test "owner-only actions deny admin" do
    refute_policy_permits Settings::ProfilePolicy, users(:named_seller), :admin_for_named_seller, *ADMIN_ONLY_ACTIONS
  end

  test "owner-only actions deny marketing" do
    refute_policy_permits Settings::ProfilePolicy, users(:named_seller), :marketing_for_named_seller, *ADMIN_ONLY_ACTIONS
  end

  test "owner-only actions deny support" do
    refute_policy_permits Settings::ProfilePolicy, users(:named_seller), :support_for_named_seller, *ADMIN_ONLY_ACTIONS
  end

  # #permitted_attributes — only owner can update username
  test "permitted_attributes allows owner to update the username" do
    policy = Settings::ProfilePolicy.new(SellerContext.new(user: users(:named_seller), seller: users(:named_seller)), users(:named_seller))
    assert(policy.permitted_attributes.any? { |attr| attr.is_a?(Hash) && attr[:user]&.include?(:username) })
  end

  test "permitted_attributes does not allow accountant to update the username" do
    policy = Settings::ProfilePolicy.new(SellerContext.new(user: users(:accountant_for_named_seller), seller: users(:named_seller)), users(:named_seller))
    refute(policy.permitted_attributes.any? { |attr| attr.is_a?(Hash) && attr[:user]&.include?(:username) })
  end

  test "permitted_attributes does not allow admin to update the username" do
    policy = Settings::ProfilePolicy.new(SellerContext.new(user: users(:admin_for_named_seller), seller: users(:named_seller)), users(:named_seller))
    refute(policy.permitted_attributes.any? { |attr| attr.is_a?(Hash) && attr[:user]&.include?(:username) })
  end

  test "permitted_attributes does not allow marketing to update the username" do
    policy = Settings::ProfilePolicy.new(SellerContext.new(user: users(:marketing_for_named_seller), seller: users(:named_seller)), users(:named_seller))
    refute(policy.permitted_attributes.any? { |attr| attr.is_a?(Hash) && attr[:user]&.include?(:username) })
  end

  test "permitted_attributes does not allow support to update the username" do
    policy = Settings::ProfilePolicy.new(SellerContext.new(user: users(:support_for_named_seller), seller: users(:named_seller)), users(:named_seller))
    refute(policy.permitted_attributes.any? { |attr| attr.is_a?(Hash) && attr[:user]&.include?(:username) })
  end
end
