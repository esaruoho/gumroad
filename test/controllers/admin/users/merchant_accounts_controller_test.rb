# frozen_string_literal: true

require "test_helper"

class Admin::Users::MerchantAccountsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    @user = users(:named_seller)
    @user.save! if @user.external_id.blank?
    sign_in @admin
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Users::MerchantAccountsController.ancestors, Admin::BaseController
  end

  test "GET index returns merchant_accounts payload as JSON" do
    get :index, params: { user_external_id: @user.external_id }, format: :json
    assert_response :success
    body = response.parsed_body
    assert_kind_of Array, body["merchant_accounts"]
    assert_includes body.keys, "has_stripe_account"
  end
end
