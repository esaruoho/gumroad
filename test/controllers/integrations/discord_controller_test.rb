# frozen_string_literal: true

require "test_helper"

# Partial backfill: full coverage needs DiscordApi HTTP stubs.
# We migrate the oauth_redirect path + auth-required guards.
class Integrations::DiscordControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "oauth_redirect returns 200 when code is present" do
    get :oauth_redirect, params: { code: "abc" }
    assert_response :success
  end

  test "oauth_redirect returns 400 when no code is provided" do
    get :oauth_redirect
    assert_response :bad_request
  end

  test "server_info requires authentication" do
    get :server_info, params: { code: "abc" }
    assert_response :redirect
    assert_match %r{/login\?next=}, @response.redirect_url
  end

  test "join_server with blank code or purchase_id returns json failure (no auth required)" do
    post :join_server
    assert_response :success
    assert_equal false, JSON.parse(@response.body)["success"]
  end
end
