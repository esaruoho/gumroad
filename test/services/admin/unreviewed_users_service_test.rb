# frozen_string_literal: true

require "test_helper"

class Admin::UnreviewedUsersServiceTest < ActiveSupport::TestCase
  self.use_transactional_tests = true

  setup do
    WebMock.stub_request(:get, %r{api\.pwnedpasswords\.com/range/.*}).to_return(status: 200, body: "")
    $redis.del(RedisKey.unreviewed_users_cutoff_date)
    $redis.del(RedisKey.unreviewed_users_data)
    # Clear any user_risk_state=not_reviewed users carrying balances from
    # other fixtures so the service's scope returns only what this test seeds.
    User.where(user_risk_state: "not_reviewed").update_all(user_risk_state: "compliant")
    @merchant_account_id = ActiveRecord::FixtureSet.identify(:forfeit_gumroad_stripe_account)
  end

  teardown do
    $redis.del(RedisKey.unreviewed_users_cutoff_date)
    $redis.del(RedisKey.unreviewed_users_data)
  end

  def make_unreviewed_user(amount_cents:, created_at: 1.year.ago, user_risk_state: "not_reviewed")
    user = User.create!(
      email: "unreviewed-#{SecureRandom.hex(6)}@example.com",
      password: "test-password-123!",
      confirmed_at: Time.current,
      user_risk_state: user_risk_state,
      recommendation_type: User::RecommendationType::OWN_PRODUCTS,
      created_at: created_at,
      updated_at: Time.current,
    )
    Balance.create!(
      user: user,
      merchant_account_id: @merchant_account_id,
      date: 1.day.ago.to_date,
      amount_cents: amount_cents,
      holding_amount_cents: amount_cents,
      currency: "usd",
      holding_currency: "usd",
      state: "unpaid",
    )
    user
  end

  test "#count returns the total count of unreviewed users with unpaid balance" do
    2.times { make_unreviewed_user(amount_cents: 15_000) }
    assert_equal 2, Admin::UnreviewedUsersService.new.count
  end

  test "#count excludes users with balance <= $100" do
    make_unreviewed_user(amount_cents: 5_000)
    assert_equal 0, Admin::UnreviewedUsersService.new.count
  end

  test "#users_with_unpaid_balance returns users ordered by total balance descending" do
    low = make_unreviewed_user(amount_cents: 15_000)
    high = make_unreviewed_user(amount_cents: 50_000)

    users = Admin::UnreviewedUsersService.new.users_with_unpaid_balance.to_a

    assert_equal high.id, users.first.id
    assert_equal low.id, users.last.id
  end

  test "#users_with_unpaid_balance includes total_balance_cents attribute" do
    user = make_unreviewed_user(amount_cents: 15_000)
    result = Admin::UnreviewedUsersService.new.users_with_unpaid_balance.find { |u| u.id == user.id }
    assert_equal 15_000, result.total_balance_cents.to_i
  end

  test "#users_with_unpaid_balance excludes compliant users" do
    make_unreviewed_user(amount_cents: 15_000, user_risk_state: "compliant")
    assert_empty Admin::UnreviewedUsersService.new.users_with_unpaid_balance.to_a
  end

  test "#users_with_unpaid_balance excludes users created before cutoff date" do
    make_unreviewed_user(amount_cents: 15_000, created_at: 3.years.ago)
    assert_empty Admin::UnreviewedUsersService.new.users_with_unpaid_balance.to_a
  end

  test "#users_with_unpaid_balance includes old users when cutoff_date is set in Redis" do
    old = make_unreviewed_user(amount_cents: 15_000, created_at: Date.new(2023, 6, 1))
    $redis.set(RedisKey.unreviewed_users_cutoff_date, "2023-01-01")
    ids = Admin::UnreviewedUsersService.new.users_with_unpaid_balance.map(&:id)
    assert_includes ids, old.id
  end

  test "#users_with_unpaid_balance respects the limit parameter" do
    3.times { make_unreviewed_user(amount_cents: 15_000) }
    users = Admin::UnreviewedUsersService.new.users_with_unpaid_balance(limit: 2).to_a
    assert_equal 2, users.size
  end

  test ".cached_users_data returns nil when no cached data exists" do
    $redis.del(RedisKey.unreviewed_users_data)
    assert_nil Admin::UnreviewedUsersService.cached_users_data
  end

  test ".cached_users_data returns parsed data from Redis" do
    payload = {
      users: [{ id: 1, email: "test@example.com" }],
      total_count: 1,
      cutoff_date: "2023-01-01",
      cached_at: "2024-01-01T00:00:00Z",
    }
    $redis.set(RedisKey.unreviewed_users_data, payload.to_json)

    result = Admin::UnreviewedUsersService.cached_users_data
    assert_equal "test@example.com", result[:users].first[:email]
    assert_equal 1, result[:total_count]
  end

  test ".cache_users_data! caches user data in Redis" do
    user = make_unreviewed_user(amount_cents: 15_000)
    result = Admin::UnreviewedUsersService.cache_users_data!
    assert_equal 1, result[:users].size
    assert_equal user.external_id, result[:users].first[:external_id]
    assert_equal 1, result[:total_count]
    assert_equal "2024-01-01", result[:cutoff_date]
    assert_predicate result[:cached_at], :present?
  end

  test ".cache_users_data! limits cached users to MAX_CACHED_USERS but total_count reflects true total" do
    3.times { |i| make_unreviewed_user(amount_cents: 15_000 + (i * 5_000)) }

    original = Admin::UnreviewedUsersService::MAX_CACHED_USERS
    Admin::UnreviewedUsersService.send(:remove_const, :MAX_CACHED_USERS)
    Admin::UnreviewedUsersService.const_set(:MAX_CACHED_USERS, 2)
    begin
      result = Admin::UnreviewedUsersService.cache_users_data!
      assert_equal 2, result[:users].size
      assert_equal 3, result[:total_count]
    ensure
      Admin::UnreviewedUsersService.send(:remove_const, :MAX_CACHED_USERS)
      Admin::UnreviewedUsersService.const_set(:MAX_CACHED_USERS, original)
    end
  end

  test ".cutoff_date defaults to 2024-01-01 when not set in Redis" do
    $redis.del(RedisKey.unreviewed_users_cutoff_date)
    assert_equal Date.new(2024, 1, 1), Admin::UnreviewedUsersService.cutoff_date
  end

  test ".cutoff_date reads from Redis when set" do
    $redis.set(RedisKey.unreviewed_users_cutoff_date, "2023-06-15")
    assert_equal Date.new(2023, 6, 15), Admin::UnreviewedUsersService.cutoff_date
  end
end
