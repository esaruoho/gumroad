# frozen_string_literal: true

require "test_helper"

class Audience::FollowerPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  INDEX_ACTIONS = %i[index?].freeze
  WRITE_ACTIONS = %i[update? destroy?].freeze

  test "index? grants access to owner" do
    assert_policy_permits Audience::FollowerPolicy, Follower, :named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to accountant" do
    assert_policy_permits Audience::FollowerPolicy, Follower, :accountant_for_named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to admin" do
    assert_policy_permits Audience::FollowerPolicy, Follower, :admin_for_named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to marketing" do
    assert_policy_permits Audience::FollowerPolicy, Follower, :marketing_for_named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to support" do
    assert_policy_permits Audience::FollowerPolicy, Follower, :support_for_named_seller, *INDEX_ACTIONS
  end

  test "update?/destroy? grants access to owner" do
    assert_policy_permits Audience::FollowerPolicy, Follower, :named_seller, *WRITE_ACTIONS
  end

  test "update?/destroy? denies access to accountant" do
    refute_policy_permits Audience::FollowerPolicy, Follower, :accountant_for_named_seller, *WRITE_ACTIONS
  end

  test "update?/destroy? grants access to admin" do
    assert_policy_permits Audience::FollowerPolicy, Follower, :admin_for_named_seller, *WRITE_ACTIONS
  end

  test "update?/destroy? denies access to marketing" do
    refute_policy_permits Audience::FollowerPolicy, Follower, :marketing_for_named_seller, *WRITE_ACTIONS
  end

  test "update?/destroy? grants access to support" do
    assert_policy_permits Audience::FollowerPolicy, Follower, :support_for_named_seller, *WRITE_ACTIONS
  end
end
