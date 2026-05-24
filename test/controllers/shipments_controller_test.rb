# frozen_string_literal: true

require "test_helper"

class ShipmentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "POST mark_as_shipped redirects to login when not authenticated" do
    post :mark_as_shipped, params: { purchase_id: "any" }
    assert_response :redirect
  end
end
