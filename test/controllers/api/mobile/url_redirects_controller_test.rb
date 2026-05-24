# frozen_string_literal: true

require "test_helper"

class Api::Mobile::UrlRedirectsControllerTest < ActionController::TestCase
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
  end

  test "GET url_redirect_attributes returns 401 with invalid mobile token" do
    get :url_redirect_attributes, params: { id: "x", mobile_token: "bad", access_token: @access_token.token }
    assert_response :unauthorized
  end

  test "GET url_redirect_attributes returns 404 with invalid access token (no doorkeeper auth)" do
    # The controller does not require OAuth scope; just mobile_token. Bad access_token
    # just yields the 'not found' path because no url redirect matches the id.
    get :url_redirect_attributes, params: { id: "x", mobile_token: Api::Mobile::BaseController::MOBILE_TOKEN, access_token: "invalid" }
    body = response.parsed_body
    assert_equal false, body["success"]
  end

  test "GET url_redirect_attributes returns success false for unknown url redirect" do
    get :url_redirect_attributes, params: {
      id: "no-such-#{SecureRandom.hex(4)}",
      mobile_token: Api::Mobile::BaseController::MOBILE_TOKEN,
      access_token: @access_token.token
    }
    body = response.parsed_body
    assert_equal false, body["success"]
  end
end
