# frozen_string_literal: true

require "test_helper"

class Admin::Users::PayoutInfosControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin_user = users(:admin_user)
    @user = users(:named_seller)
    @user.save! if @user.external_id.blank?
    sign_in @admin_user
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Users::PayoutInfosController.ancestors, Admin::BaseController
  end

  test "GET show returns the user's payout info as JSON" do
    get :show, params: { user_external_id: @user.external_id }, format: :json
    assert_response :success
    assert_includes response.parsed_body, "active_bank_account"
  end
end
