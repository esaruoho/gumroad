# frozen_string_literal: true

require "test_helper"

class Admin::Users::GuidsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    @user = users(:named_seller)
    @user.save! if @user.external_id.blank?
    sign_in @admin
  end

  test "inherits from Admin::Users::BaseController" do
    assert_includes Admin::Users::GuidsController.ancestors, Admin::Users::BaseController
  end

  test "GET index returns an empty array when user has no events" do
    get :index, params: { user_external_id: @user.external_id }, format: :json
    assert_response :success
    assert_equal [], response.parsed_body
  end
end
