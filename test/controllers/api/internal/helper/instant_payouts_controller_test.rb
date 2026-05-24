# frozen_string_literal: true

require "test_helper"

class Api::Internal::Helper::InstantPayoutsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @auth_header = "Bearer #{GlobalConfig.get("HELPER_TOOLS_TOKEN")}"
    @seller = users(:basic_user)
  end

  test "inherits from Api::Internal::Helper::BaseController" do
    assert_equal Api::Internal::Helper::BaseController, Api::Internal::Helper::InstantPayoutsController.superclass
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
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_equal "User not found", body["message"]
  end

  test "GET index returns balance for existing user" do
    @request.headers["Authorization"] = @auth_header
    User.define_method(:instantly_payable_unpaid_balance_cents) { 5000 }
    begin
      get :index, params: { email: @seller.email }
      assert_response :success
      body = response.parsed_body
      assert_equal true, body["success"]
      assert_equal "$50", body["balance"]
    ensure
      User.remove_method(:instantly_payable_unpaid_balance_cents) if User.instance_methods(false).include?(:instantly_payable_unpaid_balance_cents)
    end
  end

  test "POST create returns 404 when user is not found" do
    @request.headers["Authorization"] = @auth_header
    post :create, params: { email: "nope-#{SecureRandom.hex(4)}@example.com" }
    assert_response :not_found
    assert_equal "User not found", response.parsed_body["message"]
  end

  test "POST create returns success when InstantPayoutsService succeeds" do
    @request.headers["Authorization"] = @auth_header
    fake = Object.new
    fake.define_singleton_method(:perform) { { success: true } }
    InstantPayoutsService.define_singleton_method(:__orig_new, InstantPayoutsService.method(:new)) unless InstantPayoutsService.singleton_class.method_defined?(:__orig_new)
    InstantPayoutsService.define_singleton_method(:new) { |_| fake }
    begin
      post :create, params: { email: @seller.email }
      assert_response :success
      assert_equal true, response.parsed_body["success"]
    ensure
      InstantPayoutsService.singleton_class.send(:remove_method, :new)
      InstantPayoutsService.define_singleton_method(:new, InstantPayoutsService.method(:__orig_new))
      InstantPayoutsService.singleton_class.send(:remove_method, :__orig_new)
    end
  end

  test "POST create returns unprocessable_entity when service fails" do
    @request.headers["Authorization"] = @auth_header
    fake = Object.new
    fake.define_singleton_method(:perform) { { success: false, error: "Bad thing" } }
    InstantPayoutsService.define_singleton_method(:__orig_new, InstantPayoutsService.method(:new)) unless InstantPayoutsService.singleton_class.method_defined?(:__orig_new)
    InstantPayoutsService.define_singleton_method(:new) { |_| fake }
    begin
      post :create, params: { email: @seller.email }
      assert_response :unprocessable_entity
      body = response.parsed_body
      assert_equal false, body["success"]
      assert_equal "Bad thing", body["message"]
    ensure
      InstantPayoutsService.singleton_class.send(:remove_method, :new)
      InstantPayoutsService.define_singleton_method(:new, InstantPayoutsService.method(:__orig_new))
      InstantPayoutsService.singleton_class.send(:remove_method, :__orig_new)
    end
  end
end
