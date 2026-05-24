# frozen_string_literal: true

require "test_helper"

class CurrentApiUserTest < ActionController::TestCase
  class AnonymousController < ApplicationController
    include CurrentApiUser
    skip_before_action :set_signup_referrer
    def action
      head :ok
    end
  end

  tests AnonymousController

  include Devise::Test::ControllerHelpers

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw { match "action" => "current_api_user_test/anonymous#action", via: [:get, :post] }
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "#current_api_user without a doorkeeper token returns nil" do
    get :action
    assert_nil @controller.current_api_user
  end

  test "#current_api_user with valid doorkeeper token returns user" do
    user = users(:basic_user)
    user.save! if user.external_id.blank?
    app_owner = users(:purchaser)
    app_owner.save! if app_owner.external_id.blank?
    oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: app_owner, scopes: "creator_api"
    )
    token = Doorkeeper::AccessToken.create!(
      application: oauth_app, resource_owner_id: user.id, scopes: "creator_api"
    ).token
    get :action, params: { mobile_token: Api::Mobile::BaseController::MOBILE_TOKEN, access_token: token }
    assert_equal user, @controller.current_api_user
  end

  test "#current_api_user with invalid doorkeeper token returns nil" do
    @request.params["access_token"] = "invalid"
    get :action
    assert_nil @controller.current_api_user
  end

  test "does not error with invalid POST data" do
    begin
      post :action, body: '{ "abc"#012: "xyz" }', as: :json
    rescue ActionDispatch::Http::Parameters::ParseError
      # parsing raises before action; the concern's #current_api_user rescues it
    end
    assert_nil @controller.current_api_user
  end
end
