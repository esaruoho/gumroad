# frozen_string_literal: true

require "test_helper"

class Admin::Users::Products::TosViolationFlagsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    @user = users(:named_seller)
    @user.save! if @user.external_id.blank?
    @product = @user.links.first
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::Users::Products::BaseController" do
    assert_includes Admin::Users::Products::TosViolationFlagsController.ancestors, Admin::Users::Products::BaseController
  end

  test "GET index returns empty flags when user is not flagged" do
    skip "named_seller has no link fixture for products" if @product.nil?
    refute @user.flagged_for_tos_violation?
    get :index, params: { user_external_id: @user.external_id, product_external_id: @product.external_id }, format: :json
    assert_response :success
    assert_equal [], response.parsed_body["tos_violation_flags"]
  end

  test "POST create returns bad_request when reason is blank" do
    skip "named_seller has no link fixture for products" if @product.nil?
    post :create, params: {
      user_external_id: @user.external_id,
      product_external_id: @product.external_id,
      suspend_tos: { reason: "" }
    }, format: :json
    assert_response :bad_request
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_equal "Invalid request", body["error_message"]
  end
end
