# frozen_string_literal: true

require "test_helper"

class Api::V2::DirectUploadsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "edit_products"
    )
    @token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "edit_products")
  end

  test "POST create returns 401 without token" do
    post :create
    assert_response :unauthorized
  end

  test "POST create returns 400 with missing filename" do
    post :create, params: { access_token: @token.token, blob: { byte_size: 100, checksum: "abc", content_type: "image/png" } }
    assert_response :bad_request
  end

  test "POST create returns 400 with zero byte_size" do
    post :create, params: { access_token: @token.token, blob: { filename: "a.png", byte_size: 0, checksum: "abc", content_type: "image/png" } }
    assert_response :bad_request
    assert_includes response.parsed_body["error"].to_s, "byte_size"
  end

  test "POST create returns 400 for disallowed content type" do
    post :create, params: { access_token: @token.token, blob: { filename: "a.pdf", byte_size: 100, checksum: "abc", content_type: "application/pdf" } }
    assert_response :bad_request
    assert_includes response.parsed_body["error"].to_s, "content_type"
  end

  test "POST create returns 400 when byte_size exceeds max" do
    post :create, params: { access_token: @token.token, blob: { filename: "a.png", byte_size: 100.gigabytes, checksum: "abc", content_type: "image/png" } }
    assert_response :bad_request
    assert_includes response.parsed_body["error"].to_s, "maximum"
  end
end
