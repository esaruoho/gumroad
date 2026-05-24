# frozen_string_literal: true

require "test_helper"

class TeamMembershipTest < ActiveSupport::TestCase
  setup do
    @user = users(:tm_test_user)
    @seller = users(:tm_test_seller)
  end

  test "requires user, seller, role to be present" do
    team_membership = TeamMembership.new
    assert_equal false, team_membership.valid?
    assert_includes team_membership.errors.full_messages, "User can't be blank"
    assert_includes team_membership.errors.full_messages, "Seller can't be blank"
    assert_includes team_membership.errors.full_messages, "Role is not included in the list"
  end

  test "requires valid role" do
    team_membership = TeamMembership.new(user: @user, seller: @seller, role: :foo)
    assert_equal false, team_membership.valid?
    assert_includes team_membership.errors.full_messages, "Role is not included in the list"
  end

  test "validates uniqueness for seller and user when record alive" do
    team_membership = TeamMembership.create!(user: @user, seller: @seller, role: TeamMembership::ROLE_ADMIN)
    team_membership_dupe = team_membership.dup
    assert_equal false, team_membership_dupe.valid?
    assert_includes team_membership_dupe.errors.full_messages, "Seller has already been taken"
  end

  test "validates role_owner_cannot_be_assigned_to_other_users" do
    team_membership = TeamMembership.new(user: @user, seller: @seller, role: TeamMembership::ROLE_OWNER)
    assert_equal false, team_membership.valid?
    assert_includes team_membership.errors.full_messages, "Seller must match user for owner role"
  end

  test "validates owner_membership_must_exist" do
    no_owner_user = users(:tm_no_owner_user)
    team_membership = no_owner_user.user_memberships.new(seller: @seller, role: TeamMembership::ROLE_ADMIN)
    assert_equal false, team_membership.valid?
    assert_includes team_membership.errors.full_messages, "User requires owner membership to be created first"
  end

  (TeamMembership::ROLES - [TeamMembership::ROLE_OWNER]).each do |role|
    test "only_owner_role_can_be_assigned_to_natural_owner — #{role} role cannot be assigned to owner" do
      team_membership = @user.user_memberships.new(seller: @user, role: role)
      assert_equal false, team_membership.valid?
      assert_includes team_membership.errors.full_messages, "Role cannot be assigned to owner's membership"
    end
  end

  test "with deleted record — allows creating a new record" do
    team_membership = TeamMembership.create!(user: @user, seller: @seller, role: TeamMembership::ROLE_ADMIN)
    team_membership.update_as_deleted!
    assert_difference -> { TeamMembership.count }, +1 do
      @user.user_memberships.create!(seller: @seller, role: TeamMembership::ROLE_ADMIN)
    end
  end
end
