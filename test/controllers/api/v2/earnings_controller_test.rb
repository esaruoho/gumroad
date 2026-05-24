# frozen_string_literal: true

require "test_helper"

class Api::V2::EarningsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "view_sales view_tax_data"
    )
    @token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_tax_data")
  end

  test "GET show returns 401 without token" do
    get :show
    assert_response :unauthorized
  end

  test "GET show returns 403 when tax_center is not enabled" do
    get :show, params: { access_token: @token.token, year: (Time.current.year - 1).to_s }
    assert_response :forbidden
    assert_equal false, response.parsed_body["success"]
  end
end
