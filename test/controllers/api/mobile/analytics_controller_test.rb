# frozen_string_literal: true

require "test_helper"

class Api::Mobile::AnalyticsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Mobile App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "creator_api"
    )
    @access_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app, resource_owner_id: @user.id, scopes: "creator_api"
    )
    @base_params = {
      mobile_token: Api::Mobile::BaseController::MOBILE_TOKEN,
      access_token: @access_token.token
    }
  end

  test "GET by_date returns 401 with invalid mobile token" do
    get :by_date, params: @base_params.merge(mobile_token: "bad", date_range: "1w")
    assert_response :unauthorized
  end

  test "GET by_date returns 401 with invalid access token" do
    get :by_date, params: @base_params.merge(access_token: "invalid", date_range: "1w")
    assert_response :unauthorized
  end

  test "GET products returns paginated products list" do
    get :products, params: @base_params
    assert_response :success
    body = response.parsed_body
    assert body["products"].is_a?(Array)
    assert body["meta"]["pagination"].is_a?(Hash)
  end
end
