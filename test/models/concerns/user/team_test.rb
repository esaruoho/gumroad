# frozen_string_literal: true

require "test_helper"

class User::TeamTest < ActiveSupport::TestCase
  setup do
    # `named_seller` already owns multiple team_memberships including the
    # canonical owner self-membership. Use a clean seller for the "other" side.
    @user = users(:basic_user)
    @other_seller = users(:another_seller)
    # Ensure basic_user has an owner self-membership so non-owner roles work.
    TeamMembership.find_or_create_by!(user_id: @user.id, seller_id: @user.id, role: TeamMembership::ROLE_OWNER)
  end

  # ----- #member_of? -----

  test "#member_of? returns true with self as seller" do
    assert_equal true, @user.member_of?(@user)
  end

  test "#member_of? returns false without team membership" do
    assert_equal false, @user.member_of?(@other_seller)
  end

  test "#member_of? returns false with deleted team membership" do
    tm = TeamMembership.create!(user: @user, seller: @other_seller, role: TeamMembership::ROLE_ADMIN)
    tm.update!(deleted_at: Time.current)
    assert_equal false, @user.reload.member_of?(@other_seller)
  end

  test "#member_of? returns true with alive team membership" do
    TeamMembership.create!(user: @user, seller: @other_seller, role: TeamMembership::ROLE_ADMIN)
    assert_equal true, @user.member_of?(@other_seller)
  end

  # ----- #role_admin_for? -----

  test "#role_admin_for? returns true for owner" do
    assert_equal true, @user.role_admin_for?(@user)
  end

  test "#role_admin_for? returns true with admin role for other_seller" do
    TeamMembership.create!(user: @user, seller: @other_seller, role: TeamMembership::ROLE_ADMIN)
    assert_equal true, @user.role_admin_for?(@other_seller)
  end

  TeamMembership::ROLES.excluding(TeamMembership::ROLE_OWNER, TeamMembership::ROLE_ADMIN).each do |role|
    test "#role_admin_for? returns false with #{role} role for other_seller" do
      TeamMembership.create!(user: @user, seller: @other_seller, role: role)
      assert_equal false, @user.role_admin_for?(@other_seller)
    end
  end

  # ----- #role_<role>_for? -----

  TeamMembership::ROLES.excluding(TeamMembership::ROLE_OWNER, TeamMembership::ROLE_ADMIN).each do |role|
    test "#role_#{role}_for? returns true for owner" do
      assert_equal true, @user.send(:"role_#{role}_for?", @user)
    end

    test "#role_#{role}_for? returns true with #{role} role for other_seller" do
      TeamMembership.create!(user: @user, seller: @other_seller, role: role)
      assert_equal true, @user.send(:"role_#{role}_for?", @other_seller)
    end

    test "#role_#{role}_for? returns false with admin role for other_seller" do
      TeamMembership.create!(user: @user, seller: @other_seller, role: TeamMembership::ROLE_ADMIN)
      assert_equal false, @user.send(:"role_#{role}_for?", @other_seller)
    end
  end

  # ----- #user_memberships / #seller_memberships -----

  test "#user_memberships returns empty when there are no team_membership records" do
    fresh = User.new(email: "team-#{SecureRandom.hex(3)}@example.com")
    fresh.save!(validate: false)
    assert_equal 0, fresh.user_memberships.count
  end

  test "#user_memberships returns user_id-scoped rows" do
    admin_membership = TeamMembership.create!(user: @user, seller: @other_seller, role: TeamMembership::ROLE_ADMIN)
    owner_membership = TeamMembership.find_by!(user_id: @user.id, seller_id: @user.id, role: TeamMembership::ROLE_OWNER)
    other_membership = TeamMembership.find_by!(user_id: @other_seller.id, seller_id: @other_seller.id)

    rows = @user.reload.user_memberships.to_a
    assert_equal [owner_membership, admin_membership].sort_by(&:id), rows.sort_by(&:id)
    assert_not_includes rows, other_membership
    assert_equal @user, owner_membership.user
    assert_equal @user, admin_membership.user
  end

  test "#seller_memberships returns empty when there are no team_membership records" do
    fresh = User.new(email: "team-#{SecureRandom.hex(3)}@example.com")
    fresh.save!(validate: false)
    assert_equal 0, fresh.seller_memberships.count
  end

  test "#seller_memberships returns seller_id-scoped rows" do
    TeamMembership.create!(user: @user, seller: @other_seller, role: TeamMembership::ROLE_ADMIN)
    owner_membership = TeamMembership.find_by!(user_id: @user.id, seller_id: @user.id, role: TeamMembership::ROLE_OWNER)

    rows = @user.seller_memberships.to_a
    assert_equal [owner_membership], rows
    assert_equal @user, owner_membership.seller
  end

  # ----- #create_owner_membership_if_needed! -----

  test "#create_owner_membership_if_needed! creates owner membership when missing" do
    fresh = User.new(email: "team-#{SecureRandom.hex(3)}@example.com")
    fresh.save!(validate: false)
    assert_difference -> { fresh.user_memberships.count }, 1 do
      fresh.create_owner_membership_if_needed!
    end
    assert_equal true, fresh.user_memberships.last.role_owner?
  end

  test "#create_owner_membership_if_needed! does not create a record when owner membership exists" do
    assert_no_difference -> { @user.user_memberships.count } do
      @user.create_owner_membership_if_needed!
    end
  end

  # ----- #gumroad_account? -----

  test "#gumroad_account? returns false when the user's email is not ApplicationMailer::ADMIN_EMAIL" do
    assert_equal false, @user.gumroad_account?
  end

  test "#gumroad_account? returns true when the user's email is ApplicationMailer::ADMIN_EMAIL" do
    fresh = User.new(email: ApplicationMailer::ADMIN_EMAIL)
    fresh.save!(validate: false)
    assert_equal true, fresh.gumroad_account?
  end
end
