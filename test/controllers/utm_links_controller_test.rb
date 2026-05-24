# frozen_string_literal: true

require "test_helper"

class UtmLinksControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "GET index redirects to login when not authenticated" do
    get :index
    assert_response :redirect
  end

  test "POST create redirects to login when not authenticated" do
    post :create, params: { utm_link: { title: "T" } }
    assert_response :redirect
  end
end
