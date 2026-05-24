require "test_helper"

class AdminApiAuthorizationCodeTest < ActiveSupport::TestCase
  def create_code(plaintext_code: AdminApiToken.generate_plaintext_token,
                  code_verifier: "test-code-verifier",
                  actor_user: users(:admin_user),
                  expires_at: 60.seconds.from_now,
                  used_at: nil)
    AdminApiAuthorizationCode.create!(
      actor_user: actor_user,
      code_hash: AdminApiAuthorizationCode.hash_code(plaintext_code),
      code_challenge: AdminApiAuthorizationCode.code_challenge_for(code_verifier),
      expires_at: expires_at,
      used_at: used_at,
    )
  end

  test ".code_challenge_for uses S256 raw URL-safe base64 to match the Gumroad CLI" do
    code_verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"

    assert_equal "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
                 AdminApiAuthorizationCode.code_challenge_for(code_verifier)
  end

  test ".create_for! stores a hashed code with a 60 second expiry" do
    actor = users(:admin_user)
    code_challenge = AdminApiAuthorizationCode.code_challenge_for("verifier")

    freeze_time do
      plaintext_code = AdminApiAuthorizationCode.create_for!(actor_user: actor, code_challenge:)
      authorization_code = AdminApiAuthorizationCode.find_by!(code_hash: AdminApiAuthorizationCode.hash_code(plaintext_code))

      assert_equal actor, authorization_code.actor_user
      assert_equal code_challenge, authorization_code.code_challenge
      assert_equal 60.seconds.from_now, authorization_code.expires_at
    end
  end

  test ".exchange! mints an admin token and marks the code used when the PKCE verifier matches" do
    actor = users(:admin_user)
    plaintext_code = "authorization-code"
    code_verifier = "code-verifier"
    authorization_code = create_code(actor_user: actor, plaintext_code:, code_verifier:)

    plaintext_token, admin_api_token = AdminApiAuthorizationCode.exchange!(code: plaintext_code, code_verifier:)

    assert_equal actor, admin_api_token.actor_user
    assert admin_api_token.expires_at.present?
    assert_equal admin_api_token, AdminApiToken.authenticate(plaintext_token)

    authorization_code.reload
    assert authorization_code.used_at.present?
    assert_equal admin_api_token, authorization_code.admin_api_token
  end

  test ".exchange! rejects mismatched, expired, and already-used codes" do
    mismatched_code = create_code(plaintext_code: "mismatched-code", code_verifier: "expected")
    expired_code = create_code(plaintext_code: "expired-code", expires_at: 1.second.ago)
    used_code = create_code(plaintext_code: "used-code", used_at: Time.current)

    assert_nil AdminApiAuthorizationCode.exchange!(code: "mismatched-code", code_verifier: "wrong")
    assert_nil AdminApiAuthorizationCode.exchange!(code: "expired-code", code_verifier: "test-code-verifier")
    assert_nil AdminApiAuthorizationCode.exchange!(code: "used-code", code_verifier: "test-code-verifier")
    assert_nil mismatched_code.reload.admin_api_token
    assert_nil expired_code.reload.admin_api_token
    assert_nil used_code.reload.admin_api_token
  end
end
