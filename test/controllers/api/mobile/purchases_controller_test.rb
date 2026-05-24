# frozen_string_literal: true

require "test_helper"

class Api::Mobile::PurchasesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:purchaser)
    @user.save! if @user.external_id.blank?
    @app_owner = users(:basic_user)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Mobile App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "mobile_api"
    )
    @access_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app, resource_owner_id: @user.id, scopes: "mobile_api"
    )
    @valid_params = {
      mobile_token: Api::Mobile::BaseController::MOBILE_TOKEN,
      access_token: @access_token.token
    }
  end

  test "GET index returns 401 with invalid mobile token" do
    get :index, params: @valid_params.merge(mobile_token: "bad")
    assert_response :unauthorized
  end

  test "GET index returns 401 with invalid access token" do
    get :index, params: @valid_params.merge(access_token: "invalid")
    assert_response :unauthorized
  end

  test "GET index returns success true with empty products for a user with no purchases" do
    get :index, params: @valid_params
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert_equal @user.external_id, body["user_id"]
    assert body["products"].is_a?(Array)
  end
end
