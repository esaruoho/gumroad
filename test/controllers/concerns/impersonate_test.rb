# frozen_string_literal: true

require "test_helper"

class ImpersonateTest < ActionController::TestCase
  class AnonymousController < ApplicationController
    include Impersonate
    def action
      head :ok
    end
  end

  tests AnonymousController

  include Devise::Test::ControllerHelpers

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw { get "action" => "impersonate_test/anonymous#action" }
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = users(:basic_user)
    @admin = users(:admin_user)
    $redis.del(RedisKey.impersonated_user(@admin.id))
    $redis.del(RedisKey.impersonated_user(@user.id))
    $redis.del(RedisKey.impersonated_user(users(:purchaser).id))
  end

  teardown do
    $redis.del(RedisKey.impersonated_user(@admin.id))
    $redis.del(RedisKey.impersonated_user(@user.id))
    $redis.del(RedisKey.impersonated_user(users(:purchaser).id))
  end

  test "when not authenticated returns appropriate values" do
    get :action
    refute @controller.impersonating?
    assert_nil @controller.current_user
    assert_nil @controller.current_api_user
    assert_nil @controller.logged_in_user
    assert_nil @controller.impersonating_user
    assert_nil @controller.impersonated_user
  end

  test "when not authenticated handles stop_impersonating_user without raising" do
    get :action
    assert_nothing_raised { @controller.stop_impersonating_user }
  end

  test "admin web — not impersonating" do
    sign_in @admin
    get :action
    refute @controller.impersonating?
    assert_equal @admin, @controller.current_user
    assert_nil @controller.current_api_user
    assert_equal @admin, @controller.logged_in_user
    assert_nil @controller.impersonating_user
    assert_nil @controller.impersonated_user
  end

  test "admin web — impersonating" do
    sign_in @admin
    get :action
    @controller.impersonate_user(@user)
    get :action
    assert @controller.impersonating?
    assert_equal @admin, @controller.current_user
    assert_equal @user, @controller.logged_in_user
    assert_equal @admin, @controller.impersonating_user
    assert_equal @user, @controller.impersonated_user
  end

  test "admin web — stop_impersonating_user clears impersonation" do
    sign_in @admin
    get :action
    @controller.impersonate_user(@user)
    @controller.stop_impersonating_user
    get :action
    refute @controller.impersonating?
    assert_equal @admin, @controller.logged_in_user
    assert_nil @controller.impersonated_user
  end

  test "regular user can't impersonate" do
    other = users(:purchaser)
    sign_in other
    get :action
    @controller.impersonate_user(@user)
    get :action
    refute @controller.impersonating?
    assert_equal other, @controller.current_user
    assert_equal other, @controller.logged_in_user
    assert_nil @controller.impersonated_user
  end
end
