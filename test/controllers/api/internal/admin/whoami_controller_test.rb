# frozen_string_literal: true

require "test_helper"

class Api::Internal::Admin::WhoamiControllerTest < ActionController::TestCase
  tests Api::Internal::Admin::WhoamiController
  include Devise::Test::ControllerHelpers

  setup do
    WebMock.stub_request(:get, %r{api\.pwnedpasswords\.com/range/.*}).to_return(status: 200, body: "")
    @actor = users(:admin_user)
    @actor.update_columns(name: "Admin User", email: "admin-whoami@example.com")
  end

  test "GET show returns the authenticated admin actor and token metadata" do
    plaintext_token, admin_api_token = AdminApiToken.mint_with_plaintext!(actor_user_id: @actor.id, expires_at: 30.days.from_now)
    @request.headers["Authorization"] = "Bearer #{plaintext_token}"

    get :show

    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal({
      "actor" => {
        "external_id" => @actor.external_id,
        "name" => "Admin User",
        "email" => "admin-whoami@example.com"
      },
      "token" => {
        "external_id" => admin_api_token.external_id,
        "expires_at" => admin_api_token.reload.expires_at.as_json
      },
      "scopes" => ["admin"]
    }, body)
  end

  test "GET show returns a placeholder actor for the legacy admin token" do
    @prev = Object.const_defined?(:GUMROAD_ADMIN_ID) ? GUMROAD_ADMIN_ID : nil
    Object.send(:remove_const, :GUMROAD_ADMIN_ID) if Object.const_defined?(:GUMROAD_ADMIN_ID)
    Object.const_set(:GUMROAD_ADMIN_ID, @actor.id)
    plaintext_token = "legacy-admin-token"
    admin_api_token = AdminApiToken.create!(actor_user: @actor, token_hash: AdminApiToken.hash_token(plaintext_token))
    @request.headers["Authorization"] = "Bearer #{plaintext_token}"

    get :show

    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal({
      "actor" => {
        "external_id" => nil,
        "name" => "Legacy internal admin token",
        "email" => nil
      },
      "token" => {
        "external_id" => admin_api_token.external_id,
        "expires_at" => nil
      },
      "scopes" => ["admin"]
    }, body)
  ensure
    Object.send(:remove_const, :GUMROAD_ADMIN_ID) if Object.const_defined?(:GUMROAD_ADMIN_ID)
    Object.const_set(:GUMROAD_ADMIN_ID, @prev) unless @prev.nil?
  end
end
