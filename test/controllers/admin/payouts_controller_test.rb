# frozen_string_literal: true

require "test_helper"

class Admin::PayoutsControllerTest < ActionController::TestCase
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
    assert_includes Admin::PayoutsController.ancestors, Admin::BaseController
  end

  %i[show retry cancel fail sync].each do |action|
    test "#{action} raises RoutingError (404) for an unknown payout external_id" do
      assert_raises(ActionController::RoutingError) do
        process(action, method: action == :show ? "GET" : "POST", params: { external_id: "not-a-real-payout" })
      end
    end
  end
end
