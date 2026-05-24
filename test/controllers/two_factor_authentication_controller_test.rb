# frozen_string_literal: true

require "test_helper"

class TwoFactorAuthenticationControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "GET show raises 404 when no user can be resolved" do
    assert_raises(ActionController::RoutingError) do
      get :show
    end
  end

  test "POST create raises 404 when user_id resolves to no user" do
    assert_raises(ActionController::RoutingError) do
      post :create, params: { token: "abc" }
    end
  end

  test "GET verify redirects to login when @user is blank" do
    get :verify, params: { token: "abc", user_id: "missing" }
    assert_response :redirect
  end
end
