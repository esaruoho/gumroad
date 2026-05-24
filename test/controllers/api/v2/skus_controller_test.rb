# frozen_string_literal: true

require "test_helper"

class Api::V2::SkusControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @product = links(:basic_user_product)

    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "view_public"
    )
    @token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_public")
  end

  test "GET index returns 401 without token" do
    get :index, params: { link_id: @product.external_id }
    assert_response :unauthorized
  end

  test "GET index returns empty skus for non-physical, non-skus_enabled product" do
    get :index, params: { link_id: @product.external_id, access_token: @token.token }
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert_equal [], body["skus"]
  end

  test "GET index returns error for unknown product" do
    get :index, params: { link_id: "nope-#{SecureRandom.hex(4)}", access_token: @token.token }
    body = response.parsed_body
    assert_equal false, body["success"]
  end
end
