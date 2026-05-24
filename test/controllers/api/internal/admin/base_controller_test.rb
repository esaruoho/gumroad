# frozen_string_literal: true

require "test_helper"

class Api::Internal::Admin::BaseControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  tests Api::Internal::Admin::BaseController

  # Define a tiny ad-hoc subclass so we can exercise the base controller's
  # auth filters without depending on any specific descendant's behaviour.
  class TestableController < Api::Internal::Admin::BaseController
    def show
      render json: { ok: true, admin_actor_id: Current.admin_actor&.id }
    end
  end

  setup do
    @admin = users(:admin_user)
    @prev = Object.const_defined?(:GUMROAD_ADMIN_ID) ? GUMROAD_ADMIN_ID : nil
    Object.send(:remove_const, :GUMROAD_ADMIN_ID) if Object.const_defined?(:GUMROAD_ADMIN_ID)
    Object.const_set(:GUMROAD_ADMIN_ID, @admin.id)

    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get "/testable", to: "api/internal/admin/base_controller_test/testable#show"
    end
    @controller = TestableController.new
  end

  teardown do
    Object.send(:remove_const, :GUMROAD_ADMIN_ID) if Object.const_defined?(:GUMROAD_ADMIN_ID)
    Object.const_set(:GUMROAD_ADMIN_ID, @prev) unless @prev.nil?
  end

  test "returns 401 unauthenticated when no Authorization header is supplied" do
    get :show
    assert_response :unauthorized
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
    assert_equal "unauthenticated", body["message"]
  end

  test "returns 401 authorization is invalid when bearer token does not match any AdminApiToken" do
    @request.headers["Authorization"] = "Bearer this-is-not-a-real-token"
    get :show
    assert_response :unauthorized
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
    assert_equal "authorization is invalid", body["message"]
  end

  test "authorizes a valid per-actor admin token and sets Current.admin_actor" do
    plaintext_token, = AdminApiToken.mint_with_plaintext!(actor_user_id: @admin.id, expires_at: 30.days.from_now)
    @request.headers["Authorization"] = "Bearer #{plaintext_token}"
    get :show
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal true, body["ok"]
    assert_equal @admin.id, body["admin_actor_id"]
  end
end
