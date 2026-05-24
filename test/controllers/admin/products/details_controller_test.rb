# frozen_string_literal: true

require "test_helper"

class Admin::Products::DetailsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin_user = users(:admin_user)
    @product = links(:named_seller_product)
    sign_in @admin_user
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Products::DetailsController.ancestors, Admin::BaseController
  end

  test "GET show returns product details" do
    get :show, params: { product_external_id: @product.external_id }, format: :json
    assert_response :ok
    assert response.parsed_body["details"].present?
  end
end
