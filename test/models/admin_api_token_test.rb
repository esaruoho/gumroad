# frozen_string_literal: true

require "test_helper"

class AdminApiTokenTest < ActiveSupport::TestCase
  test ".mint! stores the token hash and returns the plaintext token once" do
    actor = users(:admin_user)

    plaintext_token = AdminApiToken.mint!(actor_user_id: actor.id)
    admin_api_token = AdminApiToken.find_by!(actor_user: actor, token_hash: AdminApiToken.hash_token(plaintext_token))

    assert plaintext_token.present?
    assert_equal AdminApiToken.hash_token(plaintext_token), admin_api_token.token_hash
    refute_equal plaintext_token, admin_api_token.token_hash
    assert_equal actor, admin_api_token.actor_user
    assert_match(/\A[-_0-9a-zA-Z]{21}\z/, admin_api_token.external_id)
  end

  test ".mint_with_plaintext! returns the plaintext token and token row" do
    actor = users(:admin_user)

    plaintext_token, admin_api_token = AdminApiToken.mint_with_plaintext!(actor_user_id: actor.id, expires_at: 30.days.from_now)

    assert plaintext_token.present?
    assert_equal actor, admin_api_token.actor_user
    assert_equal AdminApiToken.hash_token(plaintext_token), admin_api_token.token_hash
    assert admin_api_token.expires_at.present?
  end

  test ".seed_legacy_admin_token! creates the legacy admin token from the configured shared token" do
    actor = users(:admin_user)
    with_gumroad_admin_id(actor.id) do
      GlobalConfig.stub(:get, ->(key) { key == "INTERNAL_ADMIN_API_TOKEN" ? "legacy-token" : nil }) do
        admin_api_token = AdminApiToken.seed_legacy_admin_token!

        assert_equal actor, admin_api_token.actor_user
        assert_equal AdminApiToken.hash_token("legacy-token"), admin_api_token.token_hash

        assert_no_difference -> { AdminApiToken.count } do
          AdminApiToken.seed_legacy_admin_token!
        end
      end
    end
  end

  test ".seed_legacy_admin_token! does not create a token when shared token is blank" do
    GlobalConfig.stub(:get, ->(key) { key == "INTERNAL_ADMIN_API_TOKEN" ? "" : nil }) do
      assert_nil AdminApiToken.seed_legacy_admin_token!
      assert_equal 0, AdminApiToken.count
    end
  end

  test ".authenticate returns an active token for the matching plaintext token" do
    actor = users(:admin_user)
    plaintext_token = AdminApiToken.mint!(actor_user_id: actor.id)
    admin_api_token = AdminApiToken.find_by!(actor_user: actor, token_hash: AdminApiToken.hash_token(plaintext_token))

    assert_equal admin_api_token, AdminApiToken.authenticate(plaintext_token)
  end

  test ".authenticate does not authenticate revoked or expired tokens" do
    actor = users(:admin_user)
    revoked_plaintext_token = AdminApiToken.mint!(actor_user_id: actor.id)
    revoked_token = AdminApiToken.find_by!(actor_user: actor, token_hash: AdminApiToken.hash_token(revoked_plaintext_token))
    expired_plaintext_token = AdminApiToken.mint!(actor_user_id: actor.id, expires_at: 1.minute.ago)
    revoked_token.update!(revoked_at: Time.current)

    assert_nil AdminApiToken.authenticate(revoked_plaintext_token)
    assert_nil AdminApiToken.authenticate(expired_plaintext_token)
    assert_nil AdminApiToken.authenticate("missing")
  end

  test "#legacy_admin_token? only treats the seeded legacy row as the legacy admin token" do
    legacy_actor = users(:admin_user)
    service_actor = users(:another_seller)
    with_gumroad_admin_id(legacy_actor.id) do
      legacy_admin_token = AdminApiToken.create!(actor_user: legacy_actor, token_hash: AdminApiToken.hash_token("a"))
      later_admin_actor_token = AdminApiToken.create!(actor_user: legacy_actor, token_hash: AdminApiToken.hash_token("b"))
      service_token = AdminApiToken.create!(actor_user: service_actor, token_hash: AdminApiToken.hash_token("c"))

      assert legacy_admin_token.legacy_admin_token?
      refute later_admin_actor_token.legacy_admin_token?
      refute service_token.legacy_admin_token?
    end
  end

  test "#record_used! extends expiring tokens by 30 days capped at 90 days from creation" do
    actor = users(:admin_user)
    plaintext_token, admin_api_token = AdminApiToken.mint_with_plaintext!(actor_user_id: actor.id, expires_at: 1.day.from_now)
    created_at = 80.days.ago
    admin_api_token.update_columns(created_at: created_at, updated_at: created_at)

    freeze_time do
      admin_api_token.record_used!

      admin_api_token.reload
      assert_in_delta Time.current.to_f, admin_api_token.last_used_at.to_f, 1
      assert_in_delta (created_at + 90.days).to_f, admin_api_token.expires_at.to_f, 1
      assert_equal admin_api_token, AdminApiToken.authenticate(plaintext_token)
    end
  end

  test "#record_used! does not add expiry to service tokens" do
    actor = users(:admin_user)
    admin_api_token = AdminApiToken.create!(actor_user: actor, token_hash: AdminApiToken.hash_token("svc"), expires_at: nil)

    admin_api_token.record_used!

    assert_nil admin_api_token.reload.expires_at
    assert admin_api_token.last_used_at.present?
  end

  private
    def with_gumroad_admin_id(id)
      had_const = Object.const_defined?(:GUMROAD_ADMIN_ID)
      previous = had_const ? Object.const_get(:GUMROAD_ADMIN_ID) : nil
      Object.send(:remove_const, :GUMROAD_ADMIN_ID) if had_const
      Object.const_set(:GUMROAD_ADMIN_ID, id)
      yield
    ensure
      Object.send(:remove_const, :GUMROAD_ADMIN_ID) if Object.const_defined?(:GUMROAD_ADMIN_ID)
      Object.const_set(:GUMROAD_ADMIN_ID, previous) if had_const
    end
end
