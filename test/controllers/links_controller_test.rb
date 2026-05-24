# frozen_string_literal: true

require "test_helper"

class LinksControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "GET index redirects when not authenticated" do
    get :index
    assert_response :redirect
  end

  test "PUT update redirects when not authenticated" do
    put :update, params: { id: "any" }
    assert_response :redirect
  end
end
