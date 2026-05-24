# frozen_string_literal: true

require "test_helper"

class Api::V2::PayoutsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @seller = users(:basic_user)
    @other_seller = users(:purchaser)
    [@seller, @other_seller].each { |u| u.save! if u.external_id.blank? }

    @app_owner = users(:another_seller)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "view_payouts"
    )

    @payout = Payment.create!(
      user: @seller, state: "completed", processor: "PAYPAL", txn_id: "txn-c",
      processor_fee_cents: 10, amount_cents: 150_00, currency: "USD",
      correlation_id: "corr-c-#{SecureRandom.hex(4)}",
      payout_period_end_date: Date.yesterday,
      created_at: 1.day.ago
    )
    @payout_other = Payment.create!(
      user: @other_seller, state: "completed", processor: "PAYPAL", txn_id: "txn-c2",
      processor_fee_cents: 10, amount_cents: 100_00, currency: "USD",
      correlation_id: "corr-c-other-#{SecureRandom.hex(4)}",
      payout_period_end_date: Date.yesterday,
      created_at: 1.day.ago
    )
  end

  test "GET index returns 401 without token" do
    get :index, format: :json
    assert_response :unauthorized
  end

  test "GET index returns 403 with insufficient scope" do
    other_app = OauthApplication.create!(name: "App2", redirect_uri: "https://example.com", owner: @app_owner, scopes: "view_sales")
    token = Doorkeeper::AccessToken.create!(application: other_app, resource_owner_id: @seller.id, scopes: "view_sales")
    get :index, params: { access_token: token.token }, format: :json
    assert_response :forbidden
  end

  test "GET index returns the seller's payouts and not other seller's payouts" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @seller.id, scopes: "view_payouts")
    travel_to(Time.current + 5.minutes) do
      get :index, params: { access_token: token.token }, format: :json
    end
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    external_ids = body["payouts"].map { |p| p["id"] }.compact
    assert_includes external_ids, @payout.external_id
    refute_includes external_ids, @payout_other.external_id
  end

  test "GET index returns 400 with malformed before/after dates" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @seller.id, scopes: "view_payouts")
    get :index, params: { access_token: token.token, before: "not-a-date" }, format: :json
    assert_response :bad_request
  end

  test "GET show returns 404 for unknown payout" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @seller.id, scopes: "view_payouts")
    get :show, params: { id: "nonexistent-#{SecureRandom.hex(4)}", access_token: token.token }, format: :json
    body = response.parsed_body
    assert_equal false, body["success"]
  end

  test "GET show returns the payout for the seller" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @seller.id, scopes: "view_payouts")
    get :show, params: { id: @payout.external_id, access_token: token.token }, format: :json
    body = response.parsed_body
    assert_equal true, body["success"]
    assert_equal @payout.external_id, body["payout"]["id"]
  end
end
