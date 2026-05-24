# frozen_string_literal: true

require "test_helper"

class Admin::UnreviewedUsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin_user = users(:admin_user)
    sign_in @admin_user
    @request.headers["X-Inertia"] = "true"
    $redis.del(RedisKey.unreviewed_users_cutoff_date)
    $redis.del(RedisKey.unreviewed_users_data)
  end

  teardown do
    $redis.del(RedisKey.unreviewed_users_cutoff_date)
    $redis.del(RedisKey.unreviewed_users_data)
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::UnreviewedUsersController.ancestors, Admin::BaseController
  end

  test "GET index when not logged in redirects to login" do
    sign_out @admin_user
    get :index
    assert_redirected_to login_path(next: admin_unreviewed_users_path)
  end

  test "GET index when logged in as non-admin redirects to root" do
    sign_out @admin_user
    sign_in users(:named_seller)
    get :index
    assert_redirected_to root_path
  end

  test "GET index returns empty state with default cutoff_date when no cached data" do
    get :index
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal "Admin/UnreviewedUsers/Index", body["component"]
    props = body["props"]
    assert_empty props["users"]
    assert_equal 0, props["total_count"]
    assert_equal "2024-01-01", props["cutoff_date"]
  end

  test "GET index returns cached users with props from service" do
    unreviewed_user = users(:unreviewed_user_with_balance)
    Balance.create!(user: unreviewed_user, amount_cents: 15_000, date: Date.current,
                    currency: "usd", holding_currency: "usd", holding_amount_cents: 15_000,
                    state: "unpaid", merchant_account: merchant_accounts(:forfeit_gumroad_stripe_account))
    Admin::UnreviewedUsersService.cache_users_data!

    get :index
    assert_response :success
    props = JSON.parse(@response.body)["props"]
    external_ids = props["users"].map { |u| u["external_id"] }
    assert_includes external_ids, unreviewed_user.external_id
    assert_operator props["total_count"], :>=, 1
    assert_equal "2024-01-01", props["cutoff_date"]
  end

  test "GET index filters out users who are no longer not_reviewed" do
    user = users(:unreviewed_user_with_balance)
    Balance.create!(user: user, amount_cents: 15_000, date: Date.current,
                    currency: "usd", holding_currency: "usd", holding_amount_cents: 15_000,
                    state: "unpaid", merchant_account: merchant_accounts(:forfeit_gumroad_stripe_account))
    Admin::UnreviewedUsersService.cache_users_data!
    cached_total = JSON.parse($redis.get(RedisKey.unreviewed_users_data))["total_count"]
    user.update!(user_risk_state: "compliant")

    get :index
    props = JSON.parse(@response.body)["props"]
    external_ids = props["users"].map { |u| u["external_id"] }
    assert_not_includes external_ids, user.external_id
    assert_equal cached_total, props["total_count"]
  end
end
