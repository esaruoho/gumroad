# frozen_string_literal: true

require "test_helper"

class Api::V2::TaxFormsControllerTest < ActionController::TestCase
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

  test "GET index returns 401 without token" do
    get :index
    assert_response :unauthorized
  end

  test "GET index returns 403 when tax_center is not enabled" do
    # Default fixture user has no tax_center_enabled flag set.
    get :index, params: { access_token: @token.token }
    assert_response :forbidden
    assert_equal false, response.parsed_body["success"]
  end
end
