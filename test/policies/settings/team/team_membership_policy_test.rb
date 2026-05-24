# frozen_string_literal: true

require "test_helper"

class Settings::Team::TeamMembershipPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[update? destroy? restore?].freeze

  # Owner (named_seller) acting on a non-owner team membership (admin role).
  test "grants access to owner" do
    assert_policy_permits Settings::Team::TeamMembershipPolicy,
                          team_memberships(:admin_for_named_seller_membership),
                          :named_seller,
                          *ACTIONS
  end

  test "denies access to marketing" do
    refute_policy_permits Settings::Team::TeamMembershipPolicy,
                          team_memberships(:admin_for_named_seller_membership),
                          :marketing_for_named_seller,
                          *ACTIONS
  end

  test "denies access to support" do
    refute_policy_permits Settings::Team::TeamMembershipPolicy,
                          team_memberships(:admin_for_named_seller_membership),
                          :support_for_named_seller,
                          *ACTIONS
  end

  # destroy? — a non-owner member can also destroy their own membership when
  # they hold a role that the policy permits (marketing role here).
  test "destroy? grants access to the member acting on their own marketing membership" do
    membership = team_memberships(:marketing_for_named_seller_membership)
    assert Settings::Team::TeamMembershipPolicy
      .new(SellerContext.new(user: membership.user, seller: users(:named_seller)), membership)
      .destroy?
  end
end
