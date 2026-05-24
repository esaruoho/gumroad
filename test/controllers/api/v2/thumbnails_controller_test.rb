# frozen_string_literal: true

require "test_helper"

class Api::V2::ThumbnailsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @product = links(:basic_user_product)

    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "edit_products view_sales"
    )
  end

  test "POST create returns 401 without token" do
    post :create, params: { link_id: @product.external_id }
    assert_response :unauthorized
  end

  test "POST create returns 403 with insufficient scope" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_sales")
    post :create, params: { link_id: @product.external_id, access_token: token.token }
    assert_response :forbidden
  end

  test "POST create with edit_products and no signed_blob_id returns error" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "edit_products")
    post :create, params: { link_id: @product.external_id, access_token: token.token }
    assert_response :success
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_includes body["message"], "signed_blob_id"
  end

  test "DELETE destroy returns false when product has no thumbnail" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "edit_products")
    delete :destroy, params: { link_id: @product.external_id, access_token: token.token }
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_includes body["message"], "thumbnail"
  end
end
