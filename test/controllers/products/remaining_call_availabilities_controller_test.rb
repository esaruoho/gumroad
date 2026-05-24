# frozen_string_literal: true

require "test_helper"

class Products::RemainingCallAvailabilitiesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @product = links(:named_seller_product)
  end

  test "GET index returns 404 when product is not a call" do
    get :index, params: { product_id: @product.unique_permalink, format: :json }
    assert_response :not_found
  end

  test "GET index raises RoutingError when product not found" do
    assert_raises(ActionController::RoutingError) do
      get :index, params: { product_id: "doesnotexist", format: :json }
    end
  end
end
