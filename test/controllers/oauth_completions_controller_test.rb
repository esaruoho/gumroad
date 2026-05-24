# frozen_string_literal: true

require "test_helper"

# Partial backfill: full coverage requires Stripe::Account.retrieve VCR cassettes
# (originally :vcr). We migrate the cases that don't hit the Stripe API.
class OauthCompletionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "requires authentication when no user is signed in" do
    post :stripe
    assert_response :redirect
    assert_match %r{/login\?next=}, @response.redirect_url
  end

  test "handles invalid session data (no stripe_connect_data)" do
    sign_in @user
    session[:stripe_connect_data] = nil
    post :stripe
    assert_redirected_to settings_payments_url
    assert_equal "Invalid OAuth session", flash[:alert]
  end

  test "handles invalid session data (auth_uid missing)" do
    sign_in @user
    session[:stripe_connect_data] = { "referer" => settings_payments_path }
    post :stripe
    assert_redirected_to settings_payments_url
    assert_equal "Invalid OAuth session", flash[:alert]
  end
end
