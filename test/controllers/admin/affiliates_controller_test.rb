# frozen_string_literal: true

require "test_helper"

class Admin::AffiliatesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    sign_in @admin
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::AffiliatesController.ancestors, Admin::BaseController
  end

  test "GET index with query renders successfully" do
    get :index, params: { query: "nobody@nowhere.example" }
    assert_response :success
  end

  test "GET show raises RoutingError (404) when no matching affiliate user" do
    assert_raises(ActionController::RoutingError) do
      get :show, params: { external_id: "definitely-not-a-real-id" }
    end
  end
end
