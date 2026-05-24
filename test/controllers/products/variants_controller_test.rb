# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Products::VariantsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    @product = links(:named_seller_product)
    sign_in_as_seller(@seller)
  end

  teardown { restore_protect_against_forgery! }

  test "GET index returns the product options as JSON" do
    get :index, params: { link_id: @product.unique_permalink }
    assert_response :success
    body = JSON.parse(@response.body)
    expected = @product.options.map { |o| o.transform_keys(&:to_s) }
    assert_equal expected, body
  end

  test "GET index raises RoutingError when product not found" do
    assert_raises(ActionController::RoutingError) do
      get :index, params: { link_id: "nonexistent-permalink" }
    end
  end

  test "GET index redirects when no user signed in" do
    sign_out @seller
    get :index, params: { link_id: @product.unique_permalink }
    assert_response :redirect
  end
end
