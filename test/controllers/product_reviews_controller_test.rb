# frozen_string_literal: true

require "test_helper"

class ProductReviewsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @product = links(:basic_user_product)
  end

  test "GET index returns 404 when product is not found" do
    get :index, params: { product_id: "missing-#{SecureRandom.hex(4)}" }
    assert_response :not_found
  end

  test "GET index returns 403 when product reviews are hidden and viewer is not the owner" do
    @product.update!(display_product_reviews: false)
    get :index, params: { product_id: @product.external_id }
    assert_response :forbidden
  end

  test "GET index returns reviews and pagination when display is enabled" do
    @product.update!(display_product_reviews: true)
    get :index, params: { product_id: @product.external_id }
    assert_response :success
    body = response.parsed_body
    assert body.key?("reviews")
    assert body.key?("pagination")
    assert body["reviews"].is_a?(Array)
  end

  test "GET show returns 404 for unknown review" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get :show, params: { id: "missing-#{SecureRandom.hex(4)}" }
    end
  end
end
