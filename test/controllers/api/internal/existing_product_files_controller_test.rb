# frozen_string_literal: true

require "test_helper"

class Api::Internal::ExistingProductFilesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @seller = users(:named_seller)
    @product = links(:named_seller_product)
    @admin = users(:admin_for_named_seller)
    sign_in @admin
    cookies.encrypted[:current_seller_id] = @seller.id
  end

  test "GET index returns error response when not signed in" do
    sign_out @admin
    cookies.encrypted[:current_seller_id] = nil
    get :index, format: :json, params: { product_id: @product.unique_permalink }
    # devise-jwt for API endpoints returns 401/redirect/404 depending on session adapter;
    # we just assert the request is not authorized (not 2XX).
    refute response.successful?
  end

  test "GET index raises 404 when product does not belong to current_seller" do
    other_product = links(:another_seller_product)
    assert_raises(ActionController::RoutingError) do
      get :index, format: :json, params: { product_id: other_product.unique_permalink }
    end
  end

  test "GET index returns existing_files for an owned product" do
    get :index, format: :json, params: { product_id: @product.unique_permalink }
    assert_response :success
    body = response.parsed_body
    assert body.key?("existing_files")
    assert body["existing_files"].is_a?(Array)
  end
end
