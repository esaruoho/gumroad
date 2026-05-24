# frozen_string_literal: true

require "test_helper"

class Api::Mobile::DevicesControllerTest < ActionController::TestCase
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
    @mobile_post = {
      mobile_token: Api::Mobile::BaseController::MOBILE_TOKEN,
      access_token: @access_token.token,
      device: { token: "device-token-#{SecureRandom.hex(4)}", device_type: "ios", app_type: "creator", app_version: "1.0" }
    }
  end

  test "POST create returns 401 with invalid mobile token" do
    post :create, params: @mobile_post.merge(mobile_token: "invalid")
    assert_response :unauthorized
  end

  test "POST create returns 401 with invalid access token" do
    post :create, params: @mobile_post.merge(access_token: "invalid-token")
    assert_response :unauthorized
  end

  test "POST create creates a device for the resource owner" do
    assert_difference "Device.count", 1 do
      post :create, params: @mobile_post
    end
    assert_response :created
    assert_equal true, response.parsed_body["success"]
    device = Device.last
    assert_equal @user.id, device.user_id
  end

  test "POST create returns unprocessable when validation fails" do
    post :create, params: @mobile_post.merge(device: { token: "", device_type: "" })
    # Device validations missing token/device_type fail
    assert_response :unprocessable_entity
    assert_equal false, response.parsed_body["success"]
  end
end
