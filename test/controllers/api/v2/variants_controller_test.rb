# frozen_string_literal: true

require "test_helper"

class Api::V2::VariantsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @product = links(:basic_user_product)
    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "view_public edit_products"
    )
    @view_token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_public")
    @edit_token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "edit_products")
  end

  test "GET index returns 401 without token" do
    get :index, params: { link_id: @product.external_id, variant_category_id: "x" }
    assert_response :unauthorized
  end

  test "GET index returns error for unknown variant_category" do
    get :index, params: { link_id: @product.external_id, variant_category_id: "nope-#{SecureRandom.hex(4)}", access_token: @view_token.token }
    body = response.parsed_body
    assert_equal false, body["success"]
  end

  test "POST create returns error for unknown variant_category" do
    post :create, params: { link_id: @product.external_id, variant_category_id: "nope-#{SecureRandom.hex(4)}", name: "Small", access_token: @edit_token.token }
    body = response.parsed_body
    assert_equal false, body["success"]
  end

  test "GET show returns error for unknown variant" do
    get :show, params: { link_id: @product.external_id, variant_category_id: "x", id: "nope-#{SecureRandom.hex(4)}", access_token: @view_token.token }
    body = response.parsed_body
    assert_equal false, body["success"]
  end
end
