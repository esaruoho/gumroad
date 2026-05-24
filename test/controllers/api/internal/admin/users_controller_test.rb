# frozen_string_literal: true

require "test_helper"

class Api::Internal::Admin::UsersControllerTest < ActionController::TestCase
  tests Api::Internal::Admin::UsersController
  include Devise::Test::ControllerHelpers

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

  test "GET info requires authorization" do
    @request.headers["Authorization"] = nil
    get :info, params: { email: @user.email }
    assert_response :unauthorized
  end

  test "GET info returns 404 when the user does not exist by email" do
    get :info, params: { email: "missing@example.com" }
    assert_response :not_found
  end

  test "GET info returns success for an existing user" do
    User.define_method(:sales_cents_total) { 0 }
    User.define_method(:unpaid_balance_cents) { 0 }
    begin
      get :info, params: { email: @user.email }
    ensure
      [:sales_cents_total, :unpaid_balance_cents].each do |m|
        User.remove_method(m) if User.instance_methods(false).include?(m)
      end
    end
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
    # `user_id` is the top-level external_id key returned via internal_admin_user_success_payload
    assert_equal @user.external_id, body["user_id"]
  end

  test "GET affiliates rejects an invalid direction" do
    get :affiliates, params: { direction: "bogus", email: @user.email }
    assert_response :bad_request
    assert_equal({ "success" => false, "message" => "direction must be 'granted' or 'received'" }, JSON.parse(@response.body))
  end
end
