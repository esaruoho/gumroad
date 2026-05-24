# frozen_string_literal: true

require "test_helper"

class Api::Internal::ProductPostsControllerTest < ActionController::TestCase
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
    refute response.successful?
  end

  test "GET index returns paginated posts for an owned product" do
    get :index, format: :json, params: { product_id: @product.unique_permalink }
    assert_response :success
    body = response.parsed_body
    assert body.is_a?(Hash)
  end
end
