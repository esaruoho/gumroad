# frozen_string_literal: true

require "test_helper"

class Api::Mobile::SessionsControllerTest < ActionController::TestCase
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
    @token = Doorkeeper::AccessToken.create!(
      application: @oauth_app, resource_owner_id: @user.id, scopes: "mobile_api"
    )
    @params = {
      mobile_token: Api::Mobile::BaseController::MOBILE_TOKEN,
      access_token: @token.token
    }
  end

  test "POST create signs in the user and returns success with email" do
    post :create, params: @params
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert_equal @user.form_email, body["user"]["email"]
  end

  test "POST create returns 401 with invalid access_token" do
    post :create, params: @params.merge(access_token: "invalid")
    assert_response :unauthorized
  end

  test "POST create returns 401 with invalid mobile_token" do
    post :create, params: @params.merge(mobile_token: "bad")
    assert_response :unauthorized
  end
end
