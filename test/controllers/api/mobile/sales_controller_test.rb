# frozen_string_literal: true

require "test_helper"

class Api::Mobile::SalesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @seller = users(:basic_user)
    @seller.save! if @seller.external_id.blank?
    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Mobile App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "mobile_api"
    )
    @access_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app, resource_owner_id: @seller.id, scopes: "mobile_api"
    )
  end

  test "GET show returns 401 with invalid mobile token" do
    get :show, params: { id: "any", mobile_token: "invalid", access_token: @access_token.token }
    assert_response :unauthorized
  end

  test "GET show returns 401 with invalid access token" do
    get :show, params: { id: "any", mobile_token: Api::Mobile::BaseController::MOBILE_TOKEN, access_token: "invalid" }
    assert_response :unauthorized
  end

  test "GET show returns not found for unknown purchase" do
    get :show, params: { id: "no-such-#{SecureRandom.hex(4)}", mobile_token: Api::Mobile::BaseController::MOBILE_TOKEN, access_token: @access_token.token }
    body = response.parsed_body
    assert_equal false, body["success"]
  end
end
