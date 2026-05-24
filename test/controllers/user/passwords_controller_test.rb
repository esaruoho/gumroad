# frozen_string_literal: true

require "test_helper"

class User::PasswordsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
    @user = users(:reset_user)
    @user.save! if @user.external_id.blank?
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  def page_props
    JSON.parse(CGI.unescapeHTML(@response.body.match(/data-page="([^"]*)"/)[1]))
  end

  test "GET #new renders the Inertia password reset page" do
    get :new
    assert_response :success
    page = page_props
    assert_equal "User/Passwords/New", page["component"]
    assert_nil page["props"]["email"]
    assert_nil page["props"]["application_name"]
  end

  test "GET #new sets the page title" do
    get :new
    assert_response :success
    assert_equal "Forgot password", @controller.send(:page_title)
  end

  test "POST #create sends an email and redirects with success" do
    post :create, params: { user: { email: @user.email } }
    assert_redirected_to login_url
    assert_equal "Password reset sent! Please make sure to check your spam folder.", flash[:notice]
  end

  test "POST #create with unknown email redirects back with warning" do
    @request.env["HTTP_REFERER"] = "/back"
    post :create, params: { user: { email: "nobody-#{SecureRandom.hex(4)}@example.com" } }
    assert_response :redirect
    assert_equal "An account does not exist with that email.", flash[:warning]
  end

  test "POST #create with blank email redirects back with warning" do
    @request.env["HTTP_REFERER"] = "/back"
    post :create, params: { user: { email: "" } }
    assert_response :redirect
    assert_equal "An account does not exist with that email.", flash[:warning]
  end

  test "GET #edit redirects to root with warning when token is invalid" do
    get :edit, params: { reset_password_token: "invalid-token-#{SecureRandom.hex(6)}" }
    assert_redirected_to root_path
    assert_equal "That reset password token doesn't look valid (or may have expired).", flash[:warning]
  end

  test "GET #edit renders Inertia page with a valid token" do
    raw_token = @user.send(:set_reset_password_token)
    get :edit, params: { reset_password_token: raw_token }
    assert_response :success
    page = page_props
    assert_equal "User/Passwords/Edit", page["component"]
    assert_equal raw_token, page["props"]["reset_password_token"]
  end
end
