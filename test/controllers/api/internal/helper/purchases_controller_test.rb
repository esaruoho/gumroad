# frozen_string_literal: true

require "test_helper"

class Api::Internal::Helper::PurchasesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  setup do
    @auth_header = "Bearer #{GlobalConfig.get("HELPER_TOOLS_TOKEN")}"
  end

  test "inherits from Api::Internal::Helper::BaseController" do
    assert_equal Api::Internal::Helper::BaseController, Api::Internal::Helper::PurchasesController.superclass
  end

  test "POST refund_last_purchase returns 401 without authorization header" do
    post :refund_last_purchase, params: { email: "x@example.com" }
    assert_response :unauthorized
  end

  test "POST refund_last_purchase returns 401 with invalid token" do
    @request.headers["Authorization"] = "Bearer not-a-real-token"
    post :refund_last_purchase, params: { email: "x@example.com" }
    assert_response :unauthorized
  end

  test "POST reassign_purchases returns 404 (or similar) when no purchases for from email" do
    @request.headers["Authorization"] = @auth_header
    post :reassign_purchases, params: { from: "no-such-#{SecureRandom.hex(4)}@example.com", to: "new@example.com" }
    body = response.parsed_body
    assert_equal false, body["success"]
  end

  test "POST resend_all_receipts returns 404 when no purchases for email" do
    @request.headers["Authorization"] = @auth_header
    post :resend_all_receipts, params: { email: "missing-#{SecureRandom.hex(4)}@example.com" }
    assert_response :not_found
    assert_equal false, response.parsed_body["success"]
  end

  test "GET search returns 400 when no parameters provided" do
    @request.headers["Authorization"] = @auth_header
    get :search
    assert_response :bad_request
    assert_equal false, response.parsed_body["success"]
  end

  test "GET search returns 404 when no purchase found" do
    @request.headers["Authorization"] = @auth_header
    get :search, params: { email: "no-such-#{SecureRandom.hex(4)}@example.com" }
    assert_response :not_found
    assert_equal false, response.parsed_body["success"]
  end
end
