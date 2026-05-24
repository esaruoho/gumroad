# frozen_string_literal: true

require "test_helper"

class Admin::Users::LatestPostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    @user = users(:named_seller)
    @user.save! if @user.external_id.blank?
    sign_in @admin
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Users::LatestPostsController.ancestors, Admin::BaseController
  end

  test "GET index returns the user's last 5 created posts as JSON" do
    get :index, params: { user_external_id: @user.external_id }, format: :json
    assert_response :success
    assert_kind_of Array, response.parsed_body
  end
end
