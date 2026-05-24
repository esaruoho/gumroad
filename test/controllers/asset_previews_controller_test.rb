# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class AssetPreviewsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    sign_in_as_seller(@admin, @seller)
    @product = links(:named_seller_product)
    @s3_url = "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/specs/test.png"
  end

  teardown { restore_protect_against_forgery! }

  test "POST create fails if not logged in" do
    sign_out @admin
    assert_no_difference -> { AssetPreview.count } do
      assert_raises(ActionController::RoutingError) do
        post :create, params: { link_id: @product.id, asset_preview: { url: @s3_url } }
      end
    end
  end

  test "POST create returns an error for a URL without a host" do
    post :create, params: { link_id: @product.unique_permalink, asset_preview: { url: "https:///path" }, format: :json }
    assert_response :ok
    assert_equal false, @response.parsed_body["success"]
  end

  test "DELETE destroy fails if not logged in" do
    sign_out @admin
    assert_raises(ActionController::RoutingError) do
      delete :destroy, params: { link_id: @product.unique_permalink, id: "ignored" }
    end
  end
end
