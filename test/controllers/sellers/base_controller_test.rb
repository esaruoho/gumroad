# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

# Anonymous-controller pattern that mirrors the original RSpec spec.
# We exercise the parent class's before_actions (authenticate_user! +
# verify_authorized) by routing through an inline subclass.
class Sellers::BaseControllerTest < ActionController::TestCase
  class AnonymousSellersController < ::Sellers::BaseController
    def index
      skip_authorization if params[:skip_auth].present?
      head :no_content
    end
  end

  tests AnonymousSellersController
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  PATH_PLACEHOLDER = "/settings"

  setup do
    boot_controller_test!
    @request.path = PATH_PLACEHOLDER
    @original_routes = Rails.application.routes
  end

  teardown do
    restore_protect_against_forgery!
  end

  def with_anon_route
    with_routing do |routes|
      routes.draw do
        get "/anon_sellers_index", to: "sellers/base_controller_test/anonymous_sellers#index"
        # Re-include host helpers used by ApplicationController#authenticate_user!
        # (it calls login_path).
        get "/login", to: "logins#new", as: :login
      end
      yield
    end
  end

  test "authenticate_user! redirects to login when not signed in" do
    with_anon_route do
      get :index
      assert_response :redirect
      assert_match %r{/login\?next=}, @response.redirect_url
    end
  end

  test "renders the page when user is signed in" do
    with_anon_route do
      sign_in users(:basic_user)
      get :index, params: { skip_auth: "1" }
      assert_response :no_content
    end
  end

  test "verify_authorized raises when not authorized" do
    with_anon_route do
      sign_in users(:basic_user)
      assert_raises(Pundit::AuthorizationNotPerformedError) do
        get :index
      end
    end
  end
end
