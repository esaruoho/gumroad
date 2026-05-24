# frozen_string_literal: true

require "test_helper"

class Api::V2::SubscribersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @seller = users(:basic_user)
    @seller.save! if @seller.external_id.blank?
    @product = links(:basic_user_product)

    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "view_sales view_payouts"
    )
  end

  test "GET index returns 401 without token" do
    get :index, params: { link_id: @product.external_id }, format: :json
    assert_response :unauthorized
  end

  test "GET index returns 403 with insufficient scope" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @seller.id, scopes: "view_payouts")
    get :index, params: { link_id: @product.external_id, access_token: token.token }, format: :json
    assert_response :forbidden
  end

  test "GET index returns success with view_sales scope (empty subscribers)" do
    # Use a fresh product with no subscriptions to avoid hitting subscription serialization edges.
    other_seller = users(:another_seller)
    other_seller.save! if other_seller.external_id.blank?
    isolated_product = Link.create!(
      user: other_seller, name: "Iso #{SecureRandom.hex(2)}",
      unique_permalink: ("isoa" + SecureRandom.alphanumeric(8).gsub(/\d/, "a")).downcase,
      price_cents: 100, native_type: "digital", filetype: "link", filegroup: "url"
    )
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: other_seller.id, scopes: "view_sales")
    get :index, params: { link_id: isolated_product.external_id, access_token: token.token }, format: :json
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert_equal [], body["subscribers"]
  end

  test "GET show returns error for unknown subscription" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @seller.id, scopes: "view_sales")
    get :show, params: { id: "missing-#{SecureRandom.hex(4)}", access_token: token.token }, format: :json
    body = response.parsed_body
    assert_equal false, body["success"]
  end
end
