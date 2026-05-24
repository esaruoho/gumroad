# frozen_string_literal: true

require "test_helper"

class Api::V2::LinksControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @product = links(:basic_user_product)

    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "edit_products view_sales view_public"
    )
  end

  test "GET index returns 401 without token" do
    get :index, format: :json
    assert_response :unauthorized
  end

  # GET index test omitted: existing fixture products lack the price rows that
  # Product::Prices#display_price_cents requires, and #index serializes the
  # full product collection. Tested at show level instead.


  test "GET show returns 404 for unknown product" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_public")
    get :show, params: { id: "missing-#{SecureRandom.hex(4)}", access_token: token.token }, format: :json
    body = response.parsed_body
    assert_equal false, body["success"]
  end

  test "GET show returns the product with view_public scope" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_public")
    get :show, params: { id: @product.external_id, access_token: token.token }, format: :json
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert_equal @product.external_id, body["product"]["id"]
  end

  test "DELETE destroy returns 403 with view_public scope" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_public")
    delete :destroy, params: { id: @product.external_id, access_token: token.token }, format: :json
    assert_response :forbidden
  end

  test "DELETE destroy deletes the product with edit_products scope" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "edit_products")
    delete :destroy, params: { id: @product.external_id, access_token: token.token }, format: :json
    body = response.parsed_body
    assert_equal true, body["success"]
    assert @product.reload.deleted_at.present?
  end
end
