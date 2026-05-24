# frozen_string_literal: true

require "test_helper"

class Api::Mobile::FeatureFlagsControllerTest < ActionController::TestCase
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
    @valid_params = {
      mobile_token: Api::Mobile::BaseController::MOBILE_TOKEN,
      access_token: @access_token.token
    }
    @feature = :test_feature_#{SecureRandom.hex(3).to_sym}
    @feature = "test_feature_#{SecureRandom.hex(3)}".to_sym
  end

  teardown do
    Feature.remove(@feature) rescue nil
  end

  test "GET show returns 401 with invalid mobile token" do
    get :show, params: @valid_params.merge(id: @feature, mobile_token: "bad")
    assert_response :unauthorized
  end

  test "GET show returns 401 with invalid access token" do
    get :show, params: @valid_params.merge(id: @feature, access_token: "bad")
    assert_response :unauthorized
  end

  test "GET show returns enabled_for_user=true when feature active for all" do
    Feature.activate(@feature)
    get :show, params: @valid_params.merge(id: @feature)
    assert_response :success
    assert_equal true, response.parsed_body["enabled_for_user"]
  end

  test "GET show returns enabled_for_user=true when feature active for the user" do
    Feature.activate_user(@feature, @user)
    get :show, params: @valid_params.merge(id: @feature)
    assert_response :success
    assert_equal true, response.parsed_body["enabled_for_user"]
  end

  test "GET show returns false when feature not active" do
    get :show, params: @valid_params.merge(id: @feature)
    assert_response :success
    assert_equal false, response.parsed_body["enabled_for_user"]
  end
end
