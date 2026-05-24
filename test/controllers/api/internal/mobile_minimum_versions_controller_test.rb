# frozen_string_literal: true

require "test_helper"

class Api::Internal::MobileMinimumVersionsControllerTest < ActionController::TestCase
  tests Api::Internal::MobileMinimumVersionsController
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?

    @oauth_app = OauthApplication.create!(
      name: "Mobile Min Versions Test App",
      redirect_uri: "https://example.com",
      owner: @app_owner,
      scopes: "account mobile_api"
    )

    $redis.del(RedisKey.mobile_minimum_version)
    $redis.del(RedisKey.mobile_minimum_update_created_at)
  end

  teardown do
    $redis.del(RedisKey.mobile_minimum_version)
    $redis.del(RedisKey.mobile_minimum_update_created_at)
  end

  test "GET show returns the minimum version values from Redis with valid access token" do
    $redis.set(RedisKey.mobile_minimum_version, "2026.03.01")
    $redis.set(RedisKey.mobile_minimum_update_created_at, "2026-03-12")
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "account")

    get :show, params: { access_token: token.token }

    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal "2026.03.01", body["minimum_version"]
    assert_equal "2026-03-12", body["minimum_update_created_at"]
  end

  test "GET show returns nil values when not set in Redis" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "account")

    get :show, params: { access_token: token.token }

    assert_response :success
    body = JSON.parse(@response.body)
    assert_nil body["minimum_version"]
    assert_nil body["minimum_update_created_at"]
  end

  test "GET show returns unauthorized without access token" do
    get :show
    assert_response :unauthorized
  end

  test "GET show returns forbidden when token has wrong scope" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "mobile_api")
    get :show, params: { access_token: token.token }
    assert_response :forbidden
  end
end
