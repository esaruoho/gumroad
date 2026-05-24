# frozen_string_literal: true

require "test_helper"

class Api::V2::CoversControllerTest < ActionController::TestCase
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

  test "POST create returns 401 without token" do
    post :create, params: { link_id: @product.external_id }
    assert_response :unauthorized
  end

  test "POST create returns error when neither signed_blob_id nor url is provided" do
    post :create, params: { link_id: @product.external_id, access_token: @token.token }
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_includes body["message"], "signed_blob_id or url"
  end

  test "POST create with invalid signed_blob_id returns error" do
    post :create, params: { link_id: @product.external_id, access_token: @token.token, signed_blob_id: "invalid" }
    body = response.parsed_body
    assert_equal false, body["success"]
  end

  test "DELETE destroy with unknown cover id returns error" do
    delete :destroy, params: { link_id: @product.external_id, id: "nope-#{SecureRandom.hex(4)}", access_token: @token.token }
    body = response.parsed_body
    assert_equal false, body["success"]
  end
end
