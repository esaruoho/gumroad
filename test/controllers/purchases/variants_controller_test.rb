# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Purchases::VariantsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    @purchase = purchases(:named_seller_call_purchase)
  end

  test "PUT update returns 404 when unauthenticated" do
    boot_controller_test!
    put :update, params: { purchase_id: @purchase.external_id, variant_id: "x", quantity: 1 }, format: :json
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
    assert_equal "Not found", body["error"]
  end

  test "PUT update returns 404 when authenticated as a different user" do
    other = users(:basic_user)
    boot_controller_test!
    sign_in other
    @request.cookie_jar.encrypted[:current_seller_id] = other.id
    put :update, params: { purchase_id: @purchase.external_id, variant_id: "x", quantity: 1 }, format: :json
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
  end

  teardown { restore_protect_against_forgery! }
end
