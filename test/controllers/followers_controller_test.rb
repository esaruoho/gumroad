# frozen_string_literal: true

require "test_helper"

class FollowersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save! if @seller.external_id.blank?
    boot_controller_test!
  end

  teardown { restore_protect_against_forgery! }

  # GET new redirects to user profile — relies on CustomDomainConfig host
  # resolution which is brittle in ActionController::TestCase (subdomain
  # routing).  Covered by integration/system tests; skip here.

  test "POST create redirects to subscribe page with notice on success" do
    post :create, params: { email: "follower@example.com", seller_id: @seller.external_id }
    assert_response :see_other
    assert_redirected_to custom_domain_subscribe_path
    assert_equal "Check your inbox to confirm your follow request.", flash[:notice]
    follower = Follower.where(user: @seller, email: "follower@example.com").last
    assert_not_nil follower
    assert_equal @seller, follower.user
  end

  test "POST create redirects with alert when email is invalid" do
    post :create, params: { email: "invalid email", seller_id: @seller.external_id }
    assert_redirected_to custom_domain_subscribe_path
    assert_includes flash[:alert].to_s, "Email invalid"
  end

  test "POST create uncancels existing deleted follow object" do
    follower = Follower.create!(user: @seller, email: "follower@example.com")
    follower.update!(deleted_at: Time.current)
    assert follower.deleted?
    post :create, params: { email: "follower@example.com", seller_id: @seller.external_id }
    refute follower.reload.deleted?
  end

  test "POST create when logged in redirects with welcome notice" do
    buyer = users(:purchaser)
    sign_in buyer
    post :create, params: { seller_id: @seller.external_id, email: buyer.email }
    assert_redirected_to custom_domain_subscribe_path
    assert_response :see_other
    assert_equal "You are now following #{@seller.name_or_username}!", flash[:notice]
  end

  test "GET confirm confirms the follow" do
    unconfirmed = Follower.create!(user: @seller, email: "uc@example.com")
    get :confirm, params: { id: unconfirmed.external_id }
    assert_redirected_to @seller.profile_url
    refute_nil unconfirmed.reload.confirmed_at
  end

  test "GET confirm returns 404 when follower is invalid" do
    assert_raises(ActionController::RoutingError) { get :confirm, params: { id: "invalid follower" } }
  end

  test "GET cancel cancels the follow" do
    follower = Follower.create!(user: @seller, email: "cancel-me@example.com")
    get :cancel, params: { id: follower.external_id }
    assert follower.reload.deleted?
    assert_response :success
  end

  test "GET cancel returns 404 when follower is invalid" do
    assert_raises(ActionController::RoutingError) { get :cancel, params: { id: "invalid" } }
  end

  test "POST from_embed_form creates a follower object" do
    post :from_embed_form, params: { email: "fef@example.com", seller_id: @seller.external_id }
    follower = Follower.where(email: "fef@example.com", user: @seller).last
    assert_not_nil follower
    assert_equal @seller, follower.user
  end

  test "POST from_embed_form redirects with warning on invalid email" do
    post :from_embed_form, params: { email: "broken-email", seller_id: @seller.external_id }
    assert_redirected_to @seller.profile_url
    assert_includes flash[:warning].to_s, "Email invalid"
  end
end
