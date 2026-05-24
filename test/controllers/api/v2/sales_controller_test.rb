# frozen_string_literal: true

require "test_helper"

class Api::V2::SalesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @seller = users(:basic_user)
    @seller.save! if @seller.external_id.blank?

    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "view_sales edit_sales mark_sales_as_shipped refund_sales"
    )
  end

  test "GET index returns 401 without token" do
    get :index, format: :json
    assert_response :unauthorized
  end

  test "GET index returns 403 with insufficient scope" do
    other_app = OauthApplication.create!(name: "App2", redirect_uri: "https://example.com", owner: @app_owner, scopes: "view_payouts")
    token = Doorkeeper::AccessToken.create!(application: other_app, resource_owner_id: @seller.id, scopes: "view_payouts")
    get :index, params: { access_token: token.token }, format: :json
    assert_response :forbidden
  end

  test "GET index returns 400 for invalid before date" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @seller.id, scopes: "view_sales")
    get :index, params: { access_token: token.token, before: "not-a-date" }, format: :json
    assert_response :bad_request
  end

  test "GET index returns 400 for invalid product_id" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @seller.id, scopes: "view_sales")
    get :index, params: { access_token: token.token, product_id: "not-valid-encrypted!!!" }, format: :json
    assert_response :bad_request
  end

  test "GET index returns success with view_sales scope" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @seller.id, scopes: "view_sales")
    get :index, params: { access_token: token.token }, format: :json
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert body["sales"].is_a?(Array)
  end

  test "GET show returns 404 for unknown sale" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @seller.id, scopes: "view_sales")
    get :show, params: { access_token: token.token, id: "missing-#{SecureRandom.hex(4)}" }, format: :json
    body = response.parsed_body
    assert_equal false, body["success"]
  end
end
