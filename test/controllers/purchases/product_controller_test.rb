# frozen_string_literal: true

require "test_helper"

class Purchases::ProductControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @purchase = purchases(:named_seller_call_purchase)
    @product = @purchase.link
    @seller = @product.user
    @request.headers["X-Inertia"] = "true"
    @request.host = "#{DOMAIN}"
    @seller.update!(username: "namedseller") unless @seller.username
  end

  test "GET show renders Inertia component with required props" do
    get :show, params: { purchase_id: @purchase.external_id }
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Purchases/Product/Show", page["component"]
    props = page["props"]
    assert_equal @product.external_id, props.dig("product", "id")
    assert_equal @product.name, props.dig("product", "name")
    assert_equal @product.price_currency_type.downcase, props.dig("product", "currency_code")
    assert_equal @product.price_cents, props.dig("product", "price_cents")
    assert_equal @seller.display_name, props.dig("product", "seller", "name")
  end

  test "GET show raises RoutingError for invalid purchase id" do
    assert_raises(ActionController::RoutingError) do
      get :show, params: { purchase_id: "1234" }
    end
  end

  test "GET show sets X-Robots-Tag noindex header" do
    get :show, params: { purchase_id: @purchase.external_id }
    assert_response :success
    assert_equal "noindex", @response.headers["X-Robots-Tag"]
  end
end
