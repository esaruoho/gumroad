# frozen_string_literal: true

require "test_helper"

class Api::V2::FilesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?

    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?
    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner, scopes: "edit_products view_sales view_public"
    )
    # Stub multipart upload to avoid hitting S3
    @orig_new = Aws::S3::Client.method(:new)
    fake_client = Object.new
    fake_client.define_singleton_method(:create_multipart_upload) { |**_| Struct.new(:upload_id).new("test-upload-id") }
    Aws::S3::Client.define_singleton_method(:new) { |*_a, **_k| fake_client }

    @orig_presigner_new = Aws::S3::Presigner.method(:new)
    fake_presigner = Object.new
    fake_presigner.define_singleton_method(:presigned_url) { |*_a, **_k| "https://example.com/presigned" }
    Aws::S3::Presigner.define_singleton_method(:new) { |*_a, **_k| fake_presigner }
  end

  teardown do
    Aws::S3::Client.define_singleton_method(:new, @orig_new) if @orig_new
    Aws::S3::Presigner.define_singleton_method(:new, @orig_presigner_new) if @orig_presigner_new
  end

  test "POST presign returns 401 without token" do
    post :presign, params: { filename: "course.pdf", file_size: 1024 * 1024 }
    assert_response :unauthorized
  end

  test "POST presign returns 403 with insufficient scope" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_public view_sales")
    post :presign, params: { filename: "course.pdf", file_size: 1024 * 1024, access_token: token.token }
    assert_response :forbidden
  end

  test "POST presign returns success with edit_products scope" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "edit_products")
    post :presign, params: { filename: "course.pdf", file_size: 1024 * 1024, access_token: token.token }
    assert_response :success
    body = response.parsed_body
    assert_equal "test-upload-id", body["upload_id"]
    assert body["key"].present?
    assert body["file_url"].present?
    assert body["parts"].is_a?(Array)
    assert body["parts"].length >= 1
  end

  test "POST presign returns 400 when filename is blank" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "edit_products")
    post :presign, params: { filename: "", file_size: 1024 * 1024, access_token: token.token }
    assert_response :bad_request
  end

  test "POST presign returns 400 when file_size is zero" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "edit_products")
    post :presign, params: { filename: "course.pdf", file_size: 0, access_token: token.token }
    assert_response :bad_request
  end
end
