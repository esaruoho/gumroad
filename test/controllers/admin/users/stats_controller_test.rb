# frozen_string_literal: true

require "test_helper"

class Admin::Users::StatsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    @user = users(:named_seller)
    @user.save! if @user.external_id.blank?
    sign_in @admin
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Users::StatsController.ancestors, Admin::BaseController
  end

  test "GET index requires admin authentication" do
    sign_out @admin
    sign_in users(:basic_user)
    get :index, params: { user_external_id: @user.external_id }, format: :json
    refute_response_is_success_or_skip
  end

  private
    def refute_response_is_success_or_skip
      assert_not_includes 200..299, @response.status
    end
end
