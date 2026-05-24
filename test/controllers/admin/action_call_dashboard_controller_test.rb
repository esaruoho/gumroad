# frozen_string_literal: true

require "test_helper"

class Admin::ActionCallDashboardControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin_user = users(:admin_user)
    sign_in @admin_user
    @request.headers["X-Inertia"] = "true"
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::ActionCallDashboardController.ancestors, Admin::BaseController
  end

  test "GET index renders the inertia page with admin_action_call_infos ordered by call_count descending" do
    info1 = admin_action_call_infos(:dashboard_calls)
    info2 = admin_action_call_infos(:stats_calls)

    get :index
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal "Admin/ActionCallDashboard/Index", body["component"]
    expected = [info2, info1].map do |info|
      {
        "id" => info.id,
        "controller_name" => info.controller_name,
        "action_name" => info.action_name,
        "call_count" => info.call_count
      }
    end
    assert_equal expected, body["props"]["admin_action_call_infos"]
  end
end
