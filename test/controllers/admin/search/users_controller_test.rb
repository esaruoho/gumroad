# frozen_string_literal: true

require "test_helper"

class Admin::Search::UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    sign_in @admin
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Search::UsersController.ancestors, Admin::BaseController
  end

  test "GET index renders the search page" do
    get :index, params: { query: "nonexistent-query-xyz" }
    assert_response :success
  end

  test "GET index without query renders the search page" do
    get :index
    assert_response :success
  end
end
