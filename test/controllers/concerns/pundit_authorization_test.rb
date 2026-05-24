# frozen_string_literal: true

require "test_helper"

# Top-level so Pundit's `Module.const_get(:DummyPolicy)` resolution finds them.
class DummyPolicy < ApplicationPolicy
  def action?
    false
  end
end

class PublicDummyPolicy
  def initialize(_context, _record)
  end

  def public_action?
    false
  end
end

# Test the PunditAuthorization concern via an anonymous controller that includes it.
class PunditAuthorizationTest < ActionController::TestCase
  class AnonymousPunditController < ApplicationController
    include PunditAuthorization

    before_action :authenticate_user!, only: [:action]
    after_action :verify_authorized

    def action
      authorize :dummy
      head :ok
    end

    def public_action
      authorize :public_dummy
      head :ok
    end
  end

  tests AnonymousPunditController
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  def with_routes
    with_routing do |r|
      r.draw do
        get :action, to: "pundit_authorization_test/anonymous_pundit#action"
        get :public_action, to: "pundit_authorization_test/anonymous_pundit#public_action"
        get "/login", to: "logins#new", as: :login
        get "/dashboard", to: "home#dashboard", as: :dashboard
      end
      yield
    end
  end

  test "pundit_user sets SellerContext with user and seller" do
    seller = users(:named_seller)
    admin = users(:admin_for_named_seller)
    sign_in admin
    @request.cookie_jar.encrypted[:current_seller_id] = seller.id

    with_routes do
      get :action
    end

    seller_context = @controller.pundit_user
    assert_equal admin, seller_context.user
    assert_equal seller, seller_context.seller
  end

  test "user_not_authorized returns 401 JSON for JSON request" do
    seller = users(:named_seller)
    admin = users(:admin_for_named_seller)
    sign_in admin
    @request.cookie_jar.encrypted[:current_seller_id] = seller.id

    with_routes do
      get :action, format: :json
    end
    assert_response :unauthorized
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
    assert_equal "Your current role as Admin cannot perform this action.", body["error"]
  end

  test "user_not_authorized returns 401 JSON for XHR request" do
    seller = users(:named_seller)
    admin = users(:admin_for_named_seller)
    sign_in admin
    @request.cookie_jar.encrypted[:current_seller_id] = seller.id

    with_routes do
      get :action, xhr: true
    end
    assert_response :unauthorized
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
  end

  test "user_not_authorized redirects to dashboard for HTML request" do
    seller = users(:named_seller)
    admin = users(:admin_for_named_seller)
    sign_in admin
    @request.cookie_jar.encrypted[:current_seller_id] = seller.id

    with_routes do
      get :action
    end
    assert_response :redirect
    assert_equal "Your current role as Admin cannot perform this action.", flash[:alert]
  end

  test "user_not_authorized with account_switched param does not set flash alert" do
    seller = users(:named_seller)
    admin = users(:admin_for_named_seller)
    sign_in admin
    @request.cookie_jar.encrypted[:current_seller_id] = seller.id

    with_routes do
      get :action, params: { account_switched: "true" }
    end
    assert_response :redirect
    refute_equal "Your current role as Admin cannot perform this action.", flash[:alert]
  end

  test "user_not_authorized returns generic message for unauthenticated request" do
    with_routes do
      get :public_action, format: :json
    end
    assert_response :unauthorized
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
    assert_equal "You are not allowed to perform this action.", body["error"]
  end
end
