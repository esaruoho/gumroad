# frozen_string_literal: true

require "test_helper"

class Api::Internal::Helper::PayoutsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @auth_header = "Bearer #{GlobalConfig.get("HELPER_TOOLS_TOKEN")}"
    @seller = users(:basic_user)
  end

  test "inherits from Api::Internal::Helper::BaseController" do
    assert_equal Api::Internal::Helper::BaseController, Api::Internal::Helper::PayoutsController.superclass
  end

  test "GET index returns 401 without authorization header" do
    get :index, params: { email: @seller.email }
    assert_response :unauthorized
  end

  test "GET index returns 401 with invalid token" do
    @request.headers["Authorization"] = "Bearer bogus"
    get :index, params: { email: @seller.email }
    assert_response :unauthorized
  end

  test "GET index returns 404 when user does not exist" do
    @request.headers["Authorization"] = @auth_header
    get :index, params: { email: "nonexistent-#{SecureRandom.hex(4)}@example.com" }
    assert_response :not_found
    assert_equal "User not found", response.parsed_body["message"]
  end

  test "GET index returns success and a payouts array" do
    @request.headers["Authorization"] = @auth_header
    get :index, params: { email: @seller.email }
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert body["last_payouts"].is_a?(Array)
  end

  test "POST create returns unprocessable when payout method is not set up" do
    @request.headers["Authorization"] = @auth_header
    post :create, params: { email: @seller.email }
    assert_response :unprocessable_entity
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_includes body["message"], "Payout method"
  end
end
