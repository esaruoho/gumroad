# frozen_string_literal: true

require "test_helper"

class Api::V2::VariantCategoriesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @product = links(:basic_user_product)
    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "view_public edit_products"
    )
    @view_token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_public")
    @edit_token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "edit_products")
  end

  test "GET index returns 401 without token" do
    get :index, params: { link_id: @product.external_id }
    assert_response :unauthorized
  end

  test "GET index returns variant_categories array" do
    get :index, params: { link_id: @product.external_id, access_token: @view_token.token }
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert body["variant_categories"].is_a?(Array)
  end

  test "GET index returns error for unknown product" do
    get :index, params: { link_id: "nope-#{SecureRandom.hex(4)}", access_token: @view_token.token }
    body = response.parsed_body
    assert_equal false, body["success"]
  end

  test "POST create with edit_products scope creates a variant_category" do
    post :create, params: { link_id: @product.external_id, access_token: @edit_token.token, title: "Size" }
    body = response.parsed_body
    assert_equal true, body["success"]
    assert body["variant_category"].is_a?(Hash)
  end

  test "DELETE destroy returns 404 for unknown variant_category" do
    delete :destroy, params: { link_id: @product.external_id, access_token: @edit_token.token, id: "nope-#{SecureRandom.hex(4)}" }
    body = response.parsed_body
    assert_equal false, body["success"]
  end
end
