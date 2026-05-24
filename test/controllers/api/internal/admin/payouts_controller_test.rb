# frozen_string_literal: true

require "test_helper"

class Api::Internal::Admin::PayoutsControllerTest < ActionController::TestCase
  tests Api::Internal::Admin::PayoutsController
  include Devise::Test::ControllerHelpers

  USER_ID_REQUIRED = "user_id is required for mutating admin actions. Use /internal/admin/users/info to look up the user_id by email."

  setup do
    WebMock.stub_request(:get, %r{api\.pwnedpasswords\.com/range/.*}).to_return(status: 200, body: "")
    @admin = users(:admin_user)
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
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
    get :index, params: { email: @user.email }
    assert_response :unauthorized
  end

  test "GET index returns bad_request without email/user_id" do
    get :index
    assert_response :bad_request
  end

  test "GET index returns 404 when user does not exist" do
    get :index, params: { email: "missing@example.com" }
    assert_response :not_found
  end

  test "POST pause returns 400 when only email is provided" do
    post :pause, params: { email: @user.email }
    assert_response :bad_request
    assert_equal({ "success" => false, "message" => USER_ID_REQUIRED }, JSON.parse(@response.body))
  end

  test "POST pause rejects mismatched expected_email" do
    post :pause, params: { user_id: @user.external_id, expected_email: "other@example.com" }
    assert_response :conflict
    assert_equal({ "success" => false, "message" => "expected_email does not match the user's current email" }, JSON.parse(@response.body))
  end

  test "POST resume returns 400 when only email is provided" do
    post :resume, params: { email: @user.email }
    assert_response :bad_request
  end
end
