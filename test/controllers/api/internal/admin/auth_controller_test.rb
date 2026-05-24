# frozen_string_literal: true

require "test_helper"

class Api::Internal::Admin::AuthControllerTest < ActionController::TestCase
  tests Api::Internal::Admin::AuthController
  include Devise::Test::ControllerHelpers

  setup do
    WebMock.stub_request(:get, %r{api\.pwnedpasswords\.com/range/.*}).to_return(status: 200, body: "")
    @actor = users(:admin_user)
    @actor.update_columns(name: "Admin User", email: "admin-auth@example.com")
  end

  def create_authorization_code(actor: @actor, plaintext_code:, code_verifier:, expires_at: 1.minute.from_now)
    code_challenge = AdminApiAuthorizationCode.code_challenge_for(code_verifier)
    AdminApiAuthorizationCode.create!(
      actor_user: actor,
      code_hash: AdminApiAuthorizationCode.hash_code(plaintext_code),
      code_challenge:,
      expires_at:
    )
  end

  test "POST exchange exchanges a valid authorization code for a human admin token" do
    create_authorization_code(plaintext_code: "authorization-code", code_verifier: "code-verifier")

    post :exchange, params: { code: "authorization-code", code_verifier: "code-verifier" }

    assert_response :ok
    body = JSON.parse(@response.body)
    admin_api_token = AdminApiToken.authenticate(body["token"])
    assert_equal @actor, admin_api_token.actor_user
    assert_equal body["token_external_id"], admin_api_token.external_id
    assert admin_api_token.expires_at.present?
    assert_equal admin_api_token.expires_at.as_json, body["expires_at"]
    assert_equal({
      "external_id" => @actor.external_id,
      "name" => "Admin User",
      "email" => "admin-auth@example.com"
    }, body["actor"])
  end

  test "POST exchange rejects single-use codes after the first exchange" do
    create_authorization_code(plaintext_code: "authorization-code", code_verifier: "code-verifier")

    post :exchange, params: { code: "authorization-code", code_verifier: "code-verifier" }
    assert_response :ok

    before = AdminApiToken.count
    post :exchange, params: { code: "authorization-code", code_verifier: "code-verifier" }
    assert_equal before, AdminApiToken.count
    assert_response :unauthorized
    assert_equal({ "success" => false, "message" => "authorization code is invalid" }, JSON.parse(@response.body))
  end

  test "POST exchange rejects expired codes and PKCE mismatches" do
    create_authorization_code(plaintext_code: "expired-code", code_verifier: "code-verifier", expires_at: 1.second.ago)
    create_authorization_code(plaintext_code: "pkce-code", code_verifier: "expected")

    post :exchange, params: { code: "expired-code", code_verifier: "test-code-verifier" }
    assert_response :unauthorized

    post :exchange, params: { code: "pkce-code", code_verifier: "wrong" }
    assert_response :unauthorized
  end

  test "POST revoke revokes the bearer token when no external id is provided" do
    plaintext_token, admin_api_token = AdminApiToken.mint_with_plaintext!(actor_user_id: @actor.id, expires_at: 30.days.from_now)
    @request.headers["Authorization"] = "Bearer #{plaintext_token}"

    post :revoke

    assert_response :ok
    assert_equal({ "success" => true }, JSON.parse(@response.body))
    assert admin_api_token.reload.revoked_at.present?
  end

  test "POST revoke revokes another token belonging to the same actor" do
    bearer_plaintext_token, bearer_token = AdminApiToken.mint_with_plaintext!(actor_user_id: @actor.id, expires_at: 30.days.from_now)
    other_plaintext_token, other_token = AdminApiToken.mint_with_plaintext!(actor_user_id: @actor.id, expires_at: 30.days.from_now)
    @request.headers["Authorization"] = "Bearer #{bearer_plaintext_token}"

    post :revoke, params: { external_id: other_token.external_id }

    assert_response :ok
    assert_nil bearer_token.reload.revoked_at
    assert other_token.reload.revoked_at.present?
    assert_nil AdminApiToken.authenticate(other_plaintext_token)
  end

  test "POST revoke records an audit log when revoking another token" do
    bearer_plaintext_token, bearer_token = AdminApiToken.mint_with_plaintext!(actor_user_id: @actor.id, expires_at: 30.days.from_now)
    _other_plaintext_token, other_token = AdminApiToken.mint_with_plaintext!(actor_user_id: @actor.id, expires_at: 30.days.from_now)
    @request.headers["Authorization"] = "Bearer #{bearer_plaintext_token}"

    before = AdminApiAuditLog.count
    post :revoke, params: { external_id: other_token.external_id }
    assert_equal before + 1, AdminApiAuditLog.count

    log = AdminApiAuditLog.last
    assert_equal "auth.revoke", log.action
    assert_equal "AdminApiToken", log.target_type
    assert_equal other_token.id, log.target_id
    assert_equal other_token.external_id, log.target_external_id
    assert_equal @actor.id, log.actor_user_id
    assert_equal bearer_token.id, log.admin_api_token_id
    assert_equal 200, log.response_status
    assert_equal other_token.external_id, log.params_snapshot["external_id"]
  end

  test "POST revoke does not revoke another actor's token" do
    other_actor = users(:purchaser)
    other_actor.save! if other_actor.external_id.blank?

    bearer_plaintext_token, = AdminApiToken.mint_with_plaintext!(actor_user_id: @actor.id, expires_at: 30.days.from_now)
    _other_plaintext_token, other_token = AdminApiToken.mint_with_plaintext!(actor_user_id: other_actor.id, expires_at: 30.days.from_now)
    @request.headers["Authorization"] = "Bearer #{bearer_plaintext_token}"

    post :revoke, params: { external_id: other_token.external_id }

    assert_response :not_found
    assert_equal({ "success" => false, "message" => "admin token not found" }, JSON.parse(@response.body))
    assert_nil other_token.reload.revoked_at
  end
end
