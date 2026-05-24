# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Products::OtherRefundPoliciesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    @product = links(:named_seller_product)
    sign_in_as_seller(@seller)
  end

  teardown { restore_protect_against_forgery! }

  test "GET index returns refund policies for other products" do
    get :index, params: { product_id: @product.unique_permalink, format: :json }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_kind_of Array, body
  end

  test "GET index 404s when no user signed in" do
    sign_out @seller
    get :index, params: { product_id: @product.unique_permalink, format: :json }
    assert_response :not_found
  end
end
