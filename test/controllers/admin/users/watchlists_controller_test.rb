# frozen_string_literal: true

require "test_helper"

class Admin::Users::WatchlistsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    @user = users(:named_seller)
    @user.save! if @user.external_id.blank?
    # named_seller has a pre-existing alive watched_user via fixtures —
    # use a different user for tests asserting "no active watch" and create.
    @unwatched_user = users(:bvi_test_seller)
    @unwatched_user.save! if @unwatched_user.external_id.blank?
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
    # WatchedUser#sync! pulls revenue via ES+Sidekiq; bypass in controller tests.
    @orig_sync = WatchedUser.instance_method(:sync!)
    WatchedUser.define_method(:sync!) { self }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
    WatchedUser.define_method(:sync!, @orig_sync) if @orig_sync
  end

  test "inherits from Admin::Users::BaseController" do
    assert_includes Admin::Users::WatchlistsController.ancestors, Admin::Users::BaseController
  end

  test "POST create returns error when revenue_threshold is blank" do
    post :create, params: { user_external_id: @user.external_id, watched_user: { revenue_threshold: "" } }, format: :json
    assert_response :unprocessable_content
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_match(/greater than zero/, body["message"])
  end

  test "POST create returns error when revenue_threshold is non-numeric" do
    post :create, params: { user_external_id: @user.external_id, watched_user: { revenue_threshold: "abc" } }, format: :json
    assert_response :unprocessable_content
    assert_equal false, response.parsed_body["success"]
  end

  test "POST create creates a watched_user with the parsed threshold" do
    assert_difference -> { @unwatched_user.watched_users.alive.count }, 1 do
      post :create, params: { user_external_id: @unwatched_user.external_id, watched_user: { revenue_threshold: "12.50", notes: "watch this one" } }, format: :json
    end
    assert_response :success
    assert_equal true, response.parsed_body["success"]
    watched = @unwatched_user.active_watched_user
    assert_not_nil watched
    assert_equal 1250, watched.revenue_threshold_cents
    assert_equal "watch this one", watched.notes
    assert_equal @admin.id, watched.created_by_id
  end

  test "PUT update returns error when user has no active watch" do
    put :update, params: { user_external_id: @unwatched_user.external_id, watched_user: { revenue_threshold: "5" } }, format: :json
    assert_response :unprocessable_content
    assert_match(/not currently being watched/, response.parsed_body["message"])
  end

  test "DELETE destroy returns error when user has no active watch" do
    delete :destroy, params: { user_external_id: @unwatched_user.external_id }, format: :json
    assert_response :unprocessable_content
    assert_equal false, response.parsed_body["success"]
  end
end
