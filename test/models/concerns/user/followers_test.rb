# frozen_string_literal: true

require "test_helper"

class User::FollowersTest < ActiveSupport::TestCase
  setup do
    WebMock.stub_request(:get, %r{api\.pwnedpasswords\.com/range/.+}).to_return(status: 200, body: "", headers: {})
  end

  test "#following returns users being followed" do
    following_user = users(:followers_test_following_user)
    not_following_user = users(:followers_test_not_following_user)
    creator_one = users(:followers_test_creator_one)
    creator_two = users(:followers_test_creator_two)
    rel_one = followers(:followers_test_rel_one)
    rel_four = followers(:followers_test_rel_four)

    assert_equal(
      [
        { external_id: rel_one.external_id, creator: creator_one },
        { external_id: rel_four.external_id, creator: creator_two },
      ].sort_by { |h| h[:external_id] },
      following_user.following.sort_by { |h| h[:external_id] }
    )
    assert_equal [], not_following_user.following
  end

  test "#follower_by_email returns the active follower matching the provided email" do
    user = users(:followers_test_creator_one)

    active = followers(:followers_test_rel_one) # active confirmed
    assert_equal active, user.follower_by_email(active.email)

    # Unconfirmed
    unconfirmed = Follower.create!(user: user, email: "unconfirmed-fbe@example.com")
    assert_nil user.follower_by_email(unconfirmed.email)

    # Deleted: rel_three is on creator_two; create one on creator_one
    deleted = Follower.create!(user: user, email: "deleted-fbe@example.com", confirmed_at: Time.current)
    deleted.mark_deleted!
    assert_nil user.follower_by_email(deleted.email)
  end

  test "#followed_by? returns true if user has confirmed follower with that email" do
    user = users(:followers_test_creator_one)

    active = followers(:followers_test_rel_one)
    assert user.followed_by?(active.email)

    unconfirmed = Follower.create!(user: user, email: "unconfirmed-fb@example.com")
    assert_not user.followed_by?(unconfirmed.email)

    deleted = Follower.create!(user: user, email: "deleted-fb@example.com", confirmed_at: Time.current)
    deleted.mark_deleted!
    assert_not user.followed_by?(deleted.email)
  end

  test "#add_follower delegates to Follower::CreateService and returns the follower object" do
    followed_user = users(:named_seller)
    logged_in_user = users(:followers_test_following_user)
    follower_email = "addfollower@example.com"

    follower = followed_user.add_follower(follower_email, source: "welcome-greeter", logged_in_user: logged_in_user)
    assert_kind_of Follower, follower
    assert_equal followed_user.id, follower.followed_id
    assert_equal follower_email, follower.email
    assert_equal "welcome-greeter", follower.source
  end

  test "#add_follower updates source when user already follows the same creator" do
    followed_user = users(:followers_test_creator_two)
    follower_email = "follower@example.com"
    follower = followers(:followers_test_rel_four)
    follower.update!(source: Follower::From::FOLLOW_PAGE)

    followed_user.add_follower(follower_email, source: Follower::From::CSV_IMPORT)

    assert_equal Follower::From::CSV_IMPORT, follower.reload.source
  end
end
