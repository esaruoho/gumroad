# frozen_string_literal: true

require "test_helper"

class SignupControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "GET new renders the signup page" do
    get :new
    assert_response :success
  end

  test "GET new with /oauth/authorize next param sets noindex header" do
    get :new, params: { next: "/oauth/authorize?client_id=foo" }
    assert_response :success
    assert_equal "noindex", @response.headers["X-Robots-Tag"]
  end
end
