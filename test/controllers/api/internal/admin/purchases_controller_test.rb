# frozen_string_literal: true

require "test_helper"

class Api::Internal::Admin::PurchasesControllerTest < ActionController::TestCase
  tests Api::Internal::Admin::PurchasesController
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

  test "GET show requires authorization" do
    @request.headers["Authorization"] = nil
    get :show, params: { id: "x" }
    assert_response :unauthorized
  end

  test "GET show returns 404 when purchase does not exist" do
    get :show, params: { id: "nonexistent" }
    assert_response :not_found
    assert_equal({ "success" => false, "message" => "Purchase not found" }, JSON.parse(@response.body))
  end

  test "GET search returns bad_request when no search params" do
    get :search
    assert_response :bad_request
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
  end

  test "GET search returns bad_request when product_title_query without query" do
    get :search, params: { product_title_query: "something" }
    assert_response :bad_request
  end

  test "GET search rejects invalid purchase_status" do
    get :search, params: { query: "x", purchase_status: "bogus" }
    assert_response :bad_request
    body = JSON.parse(@response.body)
    assert_match(/purchase_status must be one of/, body["message"])
  end

  test "GET search rejects invalid purchase_date format" do
    skip "AdminSearchService raises InvalidDateError requires ES — covered as a unit test in service spec"
  end
end
