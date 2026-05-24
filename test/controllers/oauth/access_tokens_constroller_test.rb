# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Oauth::AccessTokensControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    [@seller, @admin].each { |u| u.save(validate: false) if u.external_id.blank? }
    sign_in_as_seller(@admin, @seller)
  end

  teardown { restore_protect_against_forgery! }

  def make_app(owner: @seller)
    OauthApplication.create!(
      name: "test-app-#{SecureRandom.hex(4)}",
      redirect_uri: "https://example.com/callback",
      owner: owner,
      scopes: "edit_products"
    )
  end

  test "POST create creates an access token when user owns the application" do
    app = make_app
    assert_difference -> { Doorkeeper::AccessToken.count }, 1 do
      post :create, params: { application_id: app.external_id, format: :json }
    end
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
    assert_equal app.access_tokens.last.token, body["token"]
  end

  test "POST create returns 404 when user does not own the application" do
    other = users(:another_seller)
    other.save(validate: false) if other.external_id.blank?
    app = make_app(owner: other)
    assert_no_difference -> { Doorkeeper::AccessToken.count } do
      post :create, params: { application_id: app.external_id, format: :json }
    end
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
  end

  test "POST create returns 404 when application has been deleted" do
    app = make_app
    app.mark_deleted!
    assert_no_difference -> { Doorkeeper::AccessToken.count } do
      post :create, params: { application_id: app.external_id, format: :json }
    end
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
    assert_equal "Application not found or you don't have the permissions to modify it.", body["message"]
  end
end
