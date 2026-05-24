# frozen_string_literal: true

require "test_helper"

class Admin::HelperActionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    @user = users(:named_seller)
    @user.save! if @user.external_id.blank?
    @admin.save! if @admin.external_id.blank?
    @purchaser = users(:purchaser)
    @purchaser.save! if @purchaser.external_id.blank?
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::HelperActionsController.ancestors, Admin::BaseController
  end

  test "GET impersonate redirects to admin impersonation when authenticated as admin" do
    sign_in @admin
    get :impersonate, params: { user_external_id: @user.external_id }
    assert_redirected_to admin_impersonate_path(user_identifier: @user.external_id)
  end

  test "GET impersonate redirects to root path when not authenticated as admin" do
    sign_in @purchaser
    get :impersonate, params: { user_external_id: @user.external_id }
    assert_redirected_to root_path
  end

  test "GET impersonate returns not found for invalid user" do
    sign_in @admin
    get :impersonate, params: { user_external_id: "invalid" }
    assert_response :not_found
  end

  test "GET stripe_dashboard redirects to Stripe dashboard when authenticated as admin" do
    sign_in @admin
    ma = merchant_accounts(:radar_stripe_connect_account) # named_seller's alive stripe account
    get :stripe_dashboard, params: { user_external_id: @user.external_id }
    assert_redirected_to "https://dashboard.stripe.com/connect/accounts/#{ma.charge_processor_merchant_id}"
  end

  test "GET stripe_dashboard redirects to root path when not authenticated as admin" do
    sign_in @purchaser
    get :stripe_dashboard, params: { user_external_id: @user.external_id }
    assert_redirected_to root_path
  end

  test "GET stripe_dashboard returns not found when user has no Stripe account" do
    sign_in @admin
    get :stripe_dashboard, params: { user_external_id: @purchaser.external_id }
    assert_response :not_found
  end

  test "GET stripe_dashboard returns not found for invalid user" do
    sign_in @admin
    get :stripe_dashboard, params: { user_external_id: "invalid" }
    assert_response :not_found
  end
end
