# frozen_string_literal: true

require "test_helper"

class CheckoutControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
    @request.headers["X-Inertia"] = "true"
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "POST update redirects with alert when cart is missing/malformed" do
    post :update, params: { cart: "scalar-not-a-hash" }
    assert_response :redirect
    assert_equal "Sorry, something went wrong. Please try again.", flash[:alert]
  end
end
