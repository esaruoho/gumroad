# frozen_string_literal: true

require "test_helper"

class ConfirmationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = users(:unconfirmed_user)
    # Mint a fresh confirmation_token (Devise stores the digest).
    raw, enc = Devise.token_generator.generate(User, :confirmation_token)
    @user.update_columns(confirmation_token: enc, confirmation_sent_at: Time.current, confirmed_at: nil)
    # This app's ConfirmationsController#show looks up by the *stored* column value
    # directly (not the raw token via Devise.confirm_by_token), so the param to
    # send is the digest stored in DB.
    @confirmation_token = enc
    _ = raw
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "GET show redirects home when user already confirmed" do
    @user.confirm
    get :show, params: { confirmation_token: @confirmation_token }
    assert_redirected_to root_url
  end

  test "GET show confirms the user (logged in)" do
    sign_in @user
    refute @user.reload.confirmed?
    get :show, params: { confirmation_token: @confirmation_token }
    assert @user.reload.confirmed?
  end

  test "GET show redirects to dashboard after confirmation (logged out)" do
    get :show, params: { confirmation_token: @confirmation_token }
    assert_redirected_to dashboard_url
  end

  test "GET show confirms the user (logged out)" do
    refute @user.reload.confirmed?
    get :show, params: { confirmation_token: @confirmation_token }
    assert @user.reload.confirmed?
  end

  test "GET show logs in the user" do
    assert_nil @controller.logged_in_user
    get :show, params: { confirmation_token: @confirmation_token }
    refute_nil @controller.logged_in_user
  end

  test "GET show invalidates active sessions and keeps current one for email change" do
    old_email = @user.email
    @user.update!(unconfirmed_email: "new@example.com")

    travel_to Time.current do
      get :show, params: { confirmation_token: @confirmation_token }
      @user.reload
      assert_equal "new@example.com", @user.email
      refute_equal old_email, @user.email
      assert_nil @user.unconfirmed_email
      assert_in_delta DateTime.current.to_i, @user.last_active_sessions_invalidated_at.to_i, 1
      assert_in_delta DateTime.current.to_i, @request.env["warden"].session["last_sign_in_at"], 1
    end
  end

  test "GET show invalidates reset password token when one was issued" do
    @user.send_reset_password_instructions
    assert_predicate @user.reset_password_token, :present?
    get :show, params: { confirmation_token: @confirmation_token }
    @user.reload
    assert_nil @user.reset_password_token
    assert_nil @user.reset_password_sent_at
  end

  test "GET show does not invalidate active sessions when user already confirmed" do
    @user.confirm
    before = @user.reload.last_active_sessions_invalidated_at
    get :show, params: { confirmation_token: @confirmation_token }
    assert_equal before, @user.reload.last_active_sessions_invalidated_at
  end
end
