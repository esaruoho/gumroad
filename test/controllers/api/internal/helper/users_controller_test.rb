# frozen_string_literal: true

require "test_helper"

class Api::Internal::Helper::UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @auth_header = "Bearer #{GlobalConfig.get("HELPER_TOOLS_TOKEN")}"
    @user = users(:basic_user)
  end

  test "inherits from Api::Internal::Helper::BaseController" do
    assert_equal Api::Internal::Helper::BaseController, Api::Internal::Helper::UsersController.superclass
  end

  # user_suspension_info
  test "GET user_suspension_info returns 401 without authorization" do
    get :user_suspension_info, params: { email: @user.email }
    assert_response :unauthorized
  end

  test "GET user_suspension_info returns 400 when email is missing" do
    @request.headers["Authorization"] = @auth_header
    get :user_suspension_info
    assert_response :bad_request
    assert_equal false, response.parsed_body["success"]
  end

  test "GET user_suspension_info returns 422 when user not found" do
    @request.headers["Authorization"] = @auth_header
    get :user_suspension_info, params: { email: "nope-#{SecureRandom.hex(4)}@example.com" }
    assert_response :unprocessable_entity
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_equal "An account does not exist with that email.", body["error_message"]
  end

  test "GET user_suspension_info returns Compliant for an alive non-suspended user" do
    @request.headers["Authorization"] = @auth_header
    get :user_suspension_info, params: { email: @user.email }
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert_equal "Compliant", body["status"]
  end

  # send_reset_password_instructions
  test "POST send_reset_password_instructions returns 401 without authorization" do
    post :send_reset_password_instructions, params: { email: @user.email }
    assert_response :unauthorized
  end

  test "POST send_reset_password_instructions returns 422 for invalid email" do
    @request.headers["Authorization"] = @auth_header
    post :send_reset_password_instructions, params: { email: "not-an-email" }
    assert_response :unprocessable_entity
    assert_equal "Invalid email", response.parsed_body["error_message"]
  end

  test "POST send_reset_password_instructions returns 422 when user not found" do
    @request.headers["Authorization"] = @auth_header
    post :send_reset_password_instructions, params: { email: "nope-#{SecureRandom.hex(4)}@example.com" }
    assert_response :unprocessable_entity
    assert_equal "An account does not exist with that email.", response.parsed_body["error_message"]
  end

  # update_email
  test "POST update_email returns 422 when both emails are not provided" do
    @request.headers["Authorization"] = @auth_header
    post :update_email, params: { current_email: @user.email }
    assert_response :unprocessable_entity
  end

  test "POST update_email returns 422 for invalid new email format" do
    @request.headers["Authorization"] = @auth_header
    post :update_email, params: { current_email: @user.email, new_email: "not-an-email" }
    assert_response :unprocessable_entity
    assert_equal "Invalid new email format.", response.parsed_body["error_message"]
  end

  # update_two_factor_authentication_enabled
  test "POST update_two_factor_authentication_enabled returns 422 when email missing" do
    @request.headers["Authorization"] = @auth_header
    post :update_two_factor_authentication_enabled, params: { enabled: true }
    assert_response :unprocessable_entity
  end

  test "POST update_two_factor_authentication_enabled returns 422 when enabled missing" do
    @request.headers["Authorization"] = @auth_header
    post :update_two_factor_authentication_enabled, params: { email: @user.email }
    assert_response :unprocessable_entity
  end

  # create_comment
  test "POST create_comment returns 400 when email/external_id missing" do
    @request.headers["Authorization"] = @auth_header
    post :create_comment, params: { content: "x", idempotency_key: "k" }
    assert_response :bad_request
  end

  test "POST create_comment returns 400 when content missing" do
    @request.headers["Authorization"] = @auth_header
    post :create_comment, params: { email: @user.email, idempotency_key: "k" }
    assert_response :bad_request
  end

  test "POST create_comment returns 400 when idempotency_key missing" do
    @request.headers["Authorization"] = @auth_header
    post :create_comment, params: { email: @user.email, content: "x" }
    assert_response :bad_request
  end

  # create_appeal
  test "POST create_appeal returns 400 when email missing" do
    @request.headers["Authorization"] = @auth_header
    post :create_appeal, params: { reason: "x" }
    assert_response :bad_request
  end

  test "POST create_appeal returns 400 when reason missing" do
    @request.headers["Authorization"] = @auth_header
    post :create_appeal, params: { email: @user.email }
    assert_response :bad_request
  end

  test "POST create_appeal returns 422 when user not suspended or flagged" do
    @request.headers["Authorization"] = @auth_header
    post :create_appeal, params: { email: @user.email, reason: "please reinstate" }
    assert_response :unprocessable_entity
    assert_equal "User is not suspended or flagged", response.parsed_body["error_message"]
  end
end
