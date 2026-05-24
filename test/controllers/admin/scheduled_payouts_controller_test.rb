# frozen_string_literal: true

require "test_helper"

class Admin::ScheduledPayoutsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::ScheduledPayoutsController.ancestors, Admin::BaseController
  end

  test "GET index renders successfully" do
    get :index
    assert_response :success
  end

  test "GET index accepts a status filter" do
    get :index, params: { status: "pending" }
    assert_response :success
  end

  test "GET index ignores invalid status filters" do
    get :index, params: { status: "not-a-real-status" }
    assert_response :success
  end

  test "POST execute returns success:false for missing scheduled_payout" do
    post :execute, params: { external_id: "missing-external-id" }
    assert_response :success
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_match(/Couldn't find ScheduledPayout/, body["message"])
  end

  test "POST cancel returns success:false for missing scheduled_payout" do
    post :cancel, params: { external_id: "missing-external-id" }
    assert_response :success
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_match(/Couldn't find ScheduledPayout/, body["message"])
  end
end
