# frozen_string_literal: true

require "test_helper"

class Api::Internal::Admin::ProductsControllerTest < ActionController::TestCase
  tests Api::Internal::Admin::ProductsController
  include Devise::Test::ControllerHelpers

  setup do
    WebMock.stub_request(:get, %r{api\.pwnedpasswords\.com/range/.*}).to_return(status: 200, body: "")
    @admin = users(:admin_user)
    @seller = users(:basic_user)
    @seller.save! if @seller.external_id.blank?
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
    get :index, params: { email: @seller.email }
    assert_response :unauthorized
  end

  test "GET index returns bad_request when neither email nor external_id is provided" do
    get :index
    assert_response :bad_request
    assert_equal({ "success" => false, "message" => "email or external_id is required" }, JSON.parse(@response.body))
  end

  test "GET index returns 404 when the user does not exist by email" do
    get :index, params: { email: "missing@example.com" }
    assert_response :not_found
    assert_equal({ "success" => false, "message" => "User not found" }, JSON.parse(@response.body))
  end

  test "GET index returns 404 when external_id does not match any user" do
    get :index, params: { external_id: "nonexistent" }
    assert_response :not_found
    assert_equal({ "success" => false, "message" => "User not found" }, JSON.parse(@response.body))
  end

  test "GET index looks up the seller by external_id when provided" do
    get :index, params: { external_id: @seller.external_id }
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
    assert_kind_of Array, body["products"]
  end

  test "GET index returns an empty list with pagination metadata when the seller has no products" do
    no_products_user = users(:purchaser)
    no_products_user.save! if no_products_user.external_id.blank?
    no_products_user.products.destroy_all # ensure empty
    get :index, params: { email: no_products_user.email }
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
    assert_equal [], body["products"]
    assert_includes body["pagination"].keys, "count"
    assert_equal 1, body["pagination"]["page"]
  end
end
