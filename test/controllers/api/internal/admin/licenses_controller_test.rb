# frozen_string_literal: true

require "test_helper"

module Api
  module Internal
    module Admin
      class LicensesControllerTest < ActionController::TestCase
        tests Api::Internal::Admin::LicensesController
        include Devise::Test::ControllerHelpers

        setup do
          @admin_user = users(:admin_user)
          @license = licenses(:admin_lookup_license)
          @purchase = purchases(:licensed_admin_lookup_purchase)
          @product = links(:named_seller_product)

          @prev_gumroad_admin_id = GUMROAD_ADMIN_ID if Object.const_defined?(:GUMROAD_ADMIN_ID)
          Object.send(:remove_const, :GUMROAD_ADMIN_ID) if Object.const_defined?(:GUMROAD_ADMIN_ID)
          Object.const_set(:GUMROAD_ADMIN_ID, @admin_user.id)

          _plaintext, @token = AdminApiToken.mint_with_plaintext!(actor_user_id: @admin_user.id, expires_at: 30.days.from_now)
          @request.headers["Authorization"] = "Bearer #{_plaintext}"
        end

        teardown do
          Object.send(:remove_const, :GUMROAD_ADMIN_ID) if Object.const_defined?(:GUMROAD_ADMIN_ID)
          Object.const_set(:GUMROAD_ADMIN_ID, @prev_gumroad_admin_id) unless @prev_gumroad_admin_id.nil?
        end

        test "returns 401 when the token is invalid" do
          @request.headers["Authorization"] = "Bearer invalid-token"
          get :lookup, params: { license_key: @license.serial }
          assert_response :unauthorized
          assert_equal({ "success" => false, "message" => "authorization is invalid" }, response.parsed_body)
        end

        test "returns 401 when the token is missing" do
          @request.headers["Authorization"] = nil
          get :lookup, params: { license_key: @license.serial }
          assert_response :unauthorized
          assert_equal({ "success" => false, "message" => "unauthenticated" }, response.parsed_body)
        end

        test "returns license and purchase details for a license key" do
          get :lookup, params: { license_key: @license.serial }

          assert_response :ok
          body = response.parsed_body
          assert_equal true, body["success"]
          assert_equal 3, body["uses"]

          license_payload = body["license"]
          assert_equal "buyer@example.com", license_payload["email"]
          assert_equal @product.external_id_numeric.to_s, license_payload["product_id"]
          assert_equal @product.name, license_payload["product_name"]
          assert_equal @purchase.external_id_numeric.to_s, license_payload["purchase_id"]
          assert_equal 3, license_payload["uses"]
          assert_equal true, license_payload["enabled"]
          assert_equal false, license_payload["disabled"]

          assert_equal @purchase.external_id_numeric.to_s, body.dig("purchase", "id")
          assert_equal "buyer@example.com", body.dig("purchase", "email")
        end

        test "returns a bad request when the license key is missing" do
          get :lookup

          assert_response :bad_request
          assert_equal({ "success" => false, "message" => "license_key is required" }, response.parsed_body)
        end

        test "returns not found when the license key does not exist" do
          get :lookup, params: { license_key: "missing-key" }

          assert_response :not_found
          assert_equal({ "success" => false, "message" => "License not found" }, response.parsed_body)
        end
      end
    end
  end
end
