# frozen_string_literal: true

require "test_helper"

class LoginsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @request.headers["X-Inertia"] = "true"
  end

  test "GET new renders Logins/New inertia component" do
    get :new
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Logins/New", page["component"]
    assert_nil page["props"]["current_user"]
    assert_equal "Log In", page["props"]["title"]
  end

  test "GET new with email param sets email in props" do
    get :new, params: { email: "test@example.com" }
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "test@example.com", page["props"]["email"]
  end

  test "GET new with email in next param sets email" do
    get :new, params: { next: settings_team_invitations_path(email: "test@example.com", format: :json) }
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "test@example.com", page["props"]["email"]
  end

  test "GET new redirects with next from referrer if not supplied" do
    @request.headers["X-Inertia"] = nil
    @request.env["HTTP_REFERER"] = products_path
    get :new
    assert_redirected_to login_path(next: products_path)
  end

  test "GET new does not redirect when referer is root" do
    @request.env["HTTP_REFERER"] = root_path
    get :new
    assert_response :success
  end

  test "GET new sets noindex header when next param starts with /oauth/authorize" do
    get :new, params: { next: "/oauth/authorize?client_id=123" }
    assert_equal "noindex", @response.headers["X-Robots-Tag"]
  end

  test "GET new with OAuth next renders with application_name" do
    oauth_app = oauth_applications(:auth_presenter_app)
    get :new, params: { next: oauth_authorization_path(client_id: oauth_app.uid, redirect_uri: oauth_app.redirect_uri, scope: "edit_products") }
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal oauth_app.name, page["props"]["application_name"]
  end
end
