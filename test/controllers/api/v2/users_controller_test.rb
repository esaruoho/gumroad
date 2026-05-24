# frozen_string_literal: true

require "test_helper"

class Api::V2::UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "view_public view_sales view_profile account"
    )
  end

  test "GET show returns 401 without token" do
    get :show
    assert_response :unauthorized
  end

  test "GET show returns the user without email under view_public scope" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_public")
    get :show, params: { access_token: token.token }
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert body["user"].is_a?(Hash)
    refute body["user"].key?("email")
  end

  test "GET show with view_sales scope includes the email" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_sales")
    get :show, params: { access_token: token.token }
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert_equal @user.email, body["user"]["email"]
  end

  test "GET show with account scope returns email and display_name" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "account")
    get :show, params: { access_token: token.token }
    assert_response :success
    body = response.parsed_body
    assert_equal @user.form_email, body["user"]["email"]
    assert body["user"]["display_name"].present?
  end

  test "GET show with is_ifttt returns data wrapper" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_public")
    get :show, params: { access_token: token.token, is_ifttt: "true" }
    assert_response :success
    body = response.parsed_body
    assert body.key?("data")
  end

  test "GET ifttt_status returns success" do
    get :ifttt_status
    assert_response :success
    assert_equal "success", response.parsed_body["status"]
  end
end
