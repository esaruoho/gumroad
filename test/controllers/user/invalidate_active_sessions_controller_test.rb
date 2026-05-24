# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class User::InvalidateActiveSessionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
  end

  teardown { restore_protect_against_forgery! }

  test "redirects to login when not signed in" do
    boot_controller_test!
    put :update
    assert_response :redirect
    assert_match %r{/login\?next=}, @response.redirect_url
  end

  test "updates last_active_sessions_invalidated_at and signs out the user" do
    sign_in_as_seller(@user)
    now = DateTime.current
    travel_to(now) do
      assert_nil @user.reload.last_active_sessions_invalidated_at
      put :update
      assert_in_delta now.to_i, @user.reload.last_active_sessions_invalidated_at.to_i, 2
    end
    assert_response :success
    assert_equal true, JSON.parse(@response.body)["success"]
    assert_equal "You have been signed out from all your active sessions. Please login again.", flash[:notice]
  end
end
