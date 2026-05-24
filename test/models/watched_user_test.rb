# frozen_string_literal: true

require "test_helper"

class WatchedUserTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    assert WatchedUser.new(user: users(:accountant_for_named_seller), revenue_threshold_cents: 20_000).valid?
  end

  test "requires a positive revenue_threshold_cents" do
    user = users(:accountant_for_named_seller)
    assert_not WatchedUser.new(user: user, revenue_threshold_cents: nil).valid?
    assert_not WatchedUser.new(user: user, revenue_threshold_cents: 0).valid?
    assert_not WatchedUser.new(user: user, revenue_threshold_cents: -100).valid?
  end

  test "prevents creating a second alive watch for the same user" do
    # named_seller already has alive_watch_one via fixtures
    duplicate = WatchedUser.new(user: users(:named_seller), revenue_threshold_cents: 20_000)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base], "User is already being watched"
  end

  test "allows a new watch once the previous one is soft-deleted" do
    # another_seller has deleted_watch (soft-deleted) → new watch should be valid
    assert WatchedUser.new(user: users(:another_seller), revenue_threshold_cents: 20_000).valid?
  end

  test ".alive returns only non-deleted watches" do
    assert_includes WatchedUser.alive, watched_users(:alive_watch_one)
    assert_includes WatchedUser.alive, watched_users(:alive_watch_two)
    assert_not_includes WatchedUser.alive, watched_users(:deleted_watch)
  end

  test ".deleted returns only soft-deleted watches" do
    assert_includes WatchedUser.deleted, watched_users(:deleted_watch)
    assert_not_includes WatchedUser.deleted, watched_users(:alive_watch_one)
  end

  test ".for_user returns watches for the given user" do
    assert_includes WatchedUser.for_user(users(:named_seller)), watched_users(:alive_watch_one)
    assert_not_includes WatchedUser.for_user(users(:named_seller)), watched_users(:alive_watch_two)
    assert_includes WatchedUser.for_user(users(:basic_user)), watched_users(:alive_watch_two)
  end

  test "#sync! snapshots total revenue, current unpaid balance, and stamps last_synced_at" do
    watch = watched_users(:alive_watch_one)
    user = watch.user

    user.stub(:sales_cents_total, 15_000) do
      user.stub(:unpaid_balance_cents, 7_250) do
        watch.stub(:user, user) do
          freeze_time do
            watch.sync!
            assert_equal 15_000, watch.revenue_cents
            assert_equal 7_250, watch.unpaid_balance_cents
            assert_equal Time.current, watch.last_synced_at
          end
        end
      end
    end
  end

  test "User#watched_users and User#active_watched_user" do
    user = users(:named_seller)
    watch = watched_users(:alive_watch_one)

    assert_includes user.watched_users, watch
    assert_equal watch, user.active_watched_user

    watch.mark_deleted!

    assert_nil user.reload.active_watched_user
    assert_includes user.watched_users, watch
  end
end
