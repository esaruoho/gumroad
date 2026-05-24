# frozen_string_literal: true

require "test_helper"

class Api::Internal::Admin::ScheduledPayoutsControllerTest < ActionController::TestCase
  tests Api::Internal::Admin::ScheduledPayoutsController
  include Devise::Test::ControllerHelpers

  setup do
    WebMock.stub_request(:get, %r{api\.pwnedpasswords\.com/range/.*}).to_return(status: 200, body: "")
    @admin = users(:admin_user)
    @prev = Object.const_defined?(:GUMROAD_ADMIN_ID) ? GUMROAD_ADMIN_ID : nil
    Object.send(:remove_const, :GUMROAD_ADMIN_ID) if Object.const_defined?(:GUMROAD_ADMIN_ID)
    Object.const_set(:GUMROAD_ADMIN_ID, @admin.id)
    plaintext_token, = AdminApiToken.mint_with_plaintext!(actor_user_id: @admin.id, expires_at: 30.days.from_now)
    @request.headers["Authorization"] = "Bearer #{plaintext_token}"
  end

  teardown do
    Object.send(:remove_const, :GUMROAD_ADMIN_ID) if Object.const_defined?(:GUMROAD_ADMIN_ID)
    Object.const_set(:GUMROAD_ADMIN_ID, @prev) unless @prev.nil?
  end

  test "GET index requires authorization" do
    @request.headers["Authorization"] = nil
    get :index
    assert_response :unauthorized
  end

  test "GET index returns 400 when status is invalid" do
    get :index, params: { status: "bogus" }
    assert_response :bad_request
    assert_equal({ "success" => false, "message" => "status is invalid" }, JSON.parse(@response.body))
  end

  test "GET index caps the limit at MAX_LIMIT" do
    get :index, params: { limit: 9999 }
    assert_response :ok
    assert_equal 50, JSON.parse(@response.body)["limit"]
  end

  test "GET index uses the default limit when limit is missing or non-positive" do
    get :index
    assert_equal 20, JSON.parse(@response.body)["limit"]
    get :index, params: { limit: 0 }
    assert_equal 20, JSON.parse(@response.body)["limit"]
  end

  test "GET index returns 404 when the requested user does not exist by email" do
    get :index, params: { email: "missing@example.com" }
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
    assert_equal "User not found", body["message"]
  end
end
