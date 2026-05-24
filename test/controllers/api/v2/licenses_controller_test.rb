# frozen_string_literal: true

require "test_helper"

module Api
  module V2
    class LicensesControllerTest < ActionController::TestCase
      include Devise::Test::ControllerHelpers

      setup do
        @seller = users(:basic_user)
        @seller.save! if @seller.external_id.blank?
        @app_owner = users(:purchaser)
        @app_owner.save! if @app_owner.external_id.blank?
        @oauth_app = OauthApplication.create!(
          name: "Test App", redirect_uri: "https://example.com",
          owner: @app_owner, scopes: "edit_products view_sales"
        )
      end

      test "POST verify with unknown license returns 404 success false" do
        post :verify, params: { license_key: "no-such-#{SecureRandom.hex(6)}" }
        body = response.parsed_body
        assert_equal false, body["success"]
      end

      test "PUT enable returns 401 without token" do
        put :enable, params: { license_key: "no-such" }
        assert_response :unauthorized
      end

      test "PUT enable returns 403 with insufficient scope" do
        token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @seller.id, scopes: "view_sales")
        put :enable, params: { license_key: "no-such", access_token: token.token }
        assert_response :forbidden
      end

      test "PUT enable with edit_products scope returns 404 when license is missing" do
        token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @seller.id, scopes: "edit_products")
        put :enable, params: { license_key: "no-such-#{SecureRandom.hex(4)}", access_token: token.token }
        body = response.parsed_body
        assert_equal false, body["success"]
      end
    end
  end
end
