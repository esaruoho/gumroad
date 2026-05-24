# frozen_string_literal: true

require "test_helper"

class Api::V2::BundleContentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @product = links(:basic_user_product)
    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "edit_products"
    )
    @token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "edit_products")
  end

  test "PATCH update returns 401 without token" do
    patch :update, params: { link_id: @product.external_id }
    assert_response :unauthorized
  end

  test "PATCH update returns success:false if product is not a bundle" do
    patch :update, params: { link_id: @product.external_id, access_token: @token.token, products: [] }
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_includes body["message"], "bundle"
  end

  test "PATCH update returns error for unknown product" do
    patch :update, params: { link_id: "nope-#{SecureRandom.hex(4)}", access_token: @token.token, products: [] }
    body = response.parsed_body
    assert_equal false, body["success"]
  end
end
