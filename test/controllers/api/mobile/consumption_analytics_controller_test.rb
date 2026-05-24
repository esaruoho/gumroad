# frozen_string_literal: true

require "test_helper"

class Api::Mobile::ConsumptionAnalyticsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?

    @oauth_app = OauthApplication.create!(
      name: "Mobile App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "mobile_api"
    )
    @access_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app, resource_owner_id: @user.id, scopes: "mobile_api"
    )
    @base_params = {
      mobile_token: Api::Mobile::BaseController::MOBILE_TOKEN,
      access_token: @access_token.token
    }
  end

  test "POST create returns 401 with invalid mobile token" do
    post :create, params: @base_params.merge(mobile_token: "bad", event_type: "view")
    assert_response :unauthorized
  end

  test "POST create returns 401 with invalid access token" do
    post :create, params: @base_params.merge(access_token: "bad", event_type: "view")
    assert_response :unauthorized
  end

  test "POST create returns success:false when event params are missing" do
    post :create, params: @base_params
    assert_response :success
    assert_equal false, response.parsed_body["success"]
  end
end
