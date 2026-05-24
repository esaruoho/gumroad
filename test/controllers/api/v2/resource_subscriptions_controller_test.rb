# frozen_string_literal: true

require "test_helper"

class Api::V2::ResourceSubscriptionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "view_sales"
    )
    @token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_sales")
  end

  test "GET index returns 401 without token" do
    get :index
    assert_response :unauthorized
  end

  test "GET index with missing resource_name returns success:false" do
    get :index, params: { access_token: @token.token }
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_includes body["message"], "resource_name"
  end

  test "GET index with valid resource_name returns empty list" do
    get :index, params: { access_token: @token.token, resource_name: ResourceSubscription::VALID_RESOURCE_NAMES.first }
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert_equal [], body["resource_subscriptions"]
  end

  test "POST create with invalid post_url returns error" do
    post :create, params: { access_token: @token.token, resource_name: ResourceSubscription::VALID_RESOURCE_NAMES.first, post_url: "" }
    body = response.parsed_body
    assert_equal false, body["success"]
  end

  test "POST create with invalid resource_name returns error" do
    post :create, params: { access_token: @token.token, resource_name: "nope", post_url: "https://example.com/x" }
    body = response.parsed_body
    assert_equal false, body["success"]
  end

  test "DELETE destroy without an id returns not found" do
    delete :destroy, params: { access_token: @token.token, id: "missing-#{SecureRandom.hex(4)}" }
    body = response.parsed_body
    assert_equal false, body["success"]
  end
end
