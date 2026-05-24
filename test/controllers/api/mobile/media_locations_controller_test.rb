# frozen_string_literal: true

require "test_helper"

class Api::Mobile::MediaLocationsControllerTest < ActionController::TestCase
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

  test "POST create returns 401 with invalid mobile token" do
    post :create, params: { id: "x", mobile_token: "bad", access_token: @access_token.token }
    assert_response :unauthorized
  end

  test "POST create returns 401 with invalid access token" do
    post :create, params: { id: "x", mobile_token: Api::Mobile::BaseController::MOBILE_TOKEN, access_token: "invalid" }
    assert_response :unauthorized
  end

  test "POST create raises ActiveRecord::RecordNotFound for missing url_redirect" do
    assert_raises(ActiveRecord::RecordNotFound) do
      post :create, params: {
        id: "missing-#{SecureRandom.hex(4)}", url_redirect_id: "missing",
        mobile_token: Api::Mobile::BaseController::MOBILE_TOKEN,
        access_token: @access_token.token,
        product_file_id: "x", platform: "android", location: 1
      }
    end
  end
end
