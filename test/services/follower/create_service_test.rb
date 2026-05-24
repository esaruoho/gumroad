# frozen_string_literal: true

require "test_helper"

class Follower::CreateServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:basic_user)
    @follower_user = users(:named_seller)
    Follower.where(followed_id: @user.id).delete_all
  end

  test "returns nil when followed_user is blank" do
    assert_nil Follower::CreateService.perform(followed_user: nil, follower_email: "a@example.com")
  end

  test "returns nil when follower_email is blank" do
    assert_nil Follower::CreateService.perform(followed_user: @user, follower_email: "")
  end

  test "creates a new follower with given attributes" do
    follower = Follower::CreateService.perform(
      followed_user: @user,
      follower_email: "newfan@example.com",
      follower_attributes: { source: Follower::From::PROFILE_PAGE }
    )

    assert follower.persisted?
    assert_equal @user.id, follower.followed_id
    assert_equal "newfan@example.com", follower.email
    assert_equal Follower::From::PROFILE_PAGE, follower.source
    assert_not follower.confirmed?
    assert_not follower.deleted?
  end

  test "reactivates and un-deletes an existing deleted follower" do
    existing = @user.followers.create!(email: "comeback@example.com")
    existing.mark_deleted!

    Follower::CreateService.perform(
      followed_user: @user,
      follower_email: "comeback@example.com",
      follower_attributes: { source: "welcome-greeter", follower_user_id: @follower_user.id }
    )

    existing.reload
    assert_not existing.deleted?
    assert_equal "welcome-greeter", existing.source
    assert_equal @follower_user.id, existing.follower_user_id
  end

  test "auto-confirms when imported from CSV" do
    follower = Follower::CreateService.perform(
      followed_user: @user,
      follower_email: "imported@example.com",
      follower_attributes: { source: Follower::From::CSV_IMPORT }
    )

    assert follower.confirmed?
  end

  test "auto-confirms when logged-in user matches follower email and is confirmed" do
    confirmed_user = @follower_user
    assert confirmed_user.confirmed?, "fixture precondition: named_seller is confirmed"

    follower = Follower::CreateService.perform(
      followed_user: @user,
      follower_email: confirmed_user.email,
      logged_in_user: confirmed_user
    )

    assert follower.confirmed?
  end

  test "does not confirm when logged-in user email does not match follower email" do
    other_user = @follower_user

    follower = Follower::CreateService.perform(
      followed_user: @user,
      follower_email: "different@example.com",
      logged_in_user: other_user
    )

    assert_not follower.confirmed?
  end

  test "honors created_at override when provided" do
    backdate = 3.days.ago.beginning_of_day
    follower = Follower::CreateService.perform(
      followed_user: @user,
      follower_email: "backdated@example.com",
      follower_attributes: { created_at: backdate }
    )

    assert_in_delta backdate.to_f, follower.created_at.to_f, 2.0
  end
end
