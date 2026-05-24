# frozen_string_literal: true

require "test_helper"

class Admin::ApiTokensControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin_user = users(:admin_user)
    sign_in @admin_user
    @request.headers["X-Inertia"] = "true"
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
    if defined?(@prev_gumroad_admin_id)
      Object.send(:remove_const, :GUMROAD_ADMIN_ID) if Object.const_defined?(:GUMROAD_ADMIN_ID)
      Object.const_set(:GUMROAD_ADMIN_ID, @prev_gumroad_admin_id) unless @prev_gumroad_admin_id.nil?
    end
  end

  def make_other_admin
    users(:scheduled_payout_admin)
  end

  test "GET index lists active admin API tokens with actor and type" do
    _p, active_token = AdminApiToken.mint_with_plaintext!(actor_user_id: @admin_user.id, expires_at: 30.days.from_now)
    _p, service_token = AdminApiToken.mint_with_plaintext!(actor_user_id: @admin_user.id)
    _p, expired_token = AdminApiToken.mint_with_plaintext!(actor_user_id: @admin_user.id, expires_at: 1.day.ago)
    _p, revoked_token = AdminApiToken.mint_with_plaintext!(actor_user_id: @admin_user.id, expires_at: 30.days.from_now)
    other_admin = make_other_admin
    _p, other_admin_token = AdminApiToken.mint_with_plaintext!(actor_user_id: other_admin.id, expires_at: 30.days.from_now)
    legacy_token = create_legacy_admin_token
    revoked_token.update!(revoked_at: Time.current)

    get :index
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal "Admin/ApiTokens/Index", body["component"]
    assert_equal "Admin API tokens", body["props"]["title"]
    tokens = body["props"]["tokens"]
    external_ids = tokens.map { |t| t["external_id"] }
    assert_includes external_ids, active_token.external_id
    assert_includes external_ids, service_token.external_id
    assert_includes external_ids, other_admin_token.external_id
    assert_includes external_ids, legacy_token.external_id
    assert_not_includes external_ids, expired_token.external_id
    assert_not_includes external_ids, revoked_token.external_id
    by_id = tokens.index_by { |t| t["external_id"] }
    assert_equal "CLI", by_id[active_token.external_id]["kind"]
    assert_equal "Service", by_id[service_token.external_id]["kind"]
    assert_equal "Legacy", by_id[legacy_token.external_id]["kind"]
  end

  test "POST revoke revokes an active admin API token for any actor" do
    other_admin = make_other_admin
    _p, admin_api_token = AdminApiToken.mint_with_plaintext!(actor_user_id: other_admin.id)

    post :revoke, params: { external_id: admin_api_token.external_id }

    assert_redirected_to admin_api_tokens_path
    assert_response :see_other
    assert_equal "Admin API token revoked.", flash[:notice]
    assert_not_nil admin_api_token.reload.revoked_at
  end

  test "POST revoke does not revoke an inactive token" do
    _p, admin_api_token = AdminApiToken.mint_with_plaintext!(actor_user_id: @admin_user.id, expires_at: 1.day.ago)

    post :revoke, params: { external_id: admin_api_token.external_id }

    assert_redirected_to admin_api_tokens_path
    assert_equal "Active admin API token not found.", flash[:alert]
    assert_nil admin_api_token.reload.revoked_at
  end

  private
    def create_legacy_admin_token
      legacy_actor_id = User.maximum(:id).to_i + 1_000_000
      @prev_gumroad_admin_id = Object.const_defined?(:GUMROAD_ADMIN_ID) ? GUMROAD_ADMIN_ID : nil
      Object.send(:remove_const, :GUMROAD_ADMIN_ID) if Object.const_defined?(:GUMROAD_ADMIN_ID)
      Object.const_set(:GUMROAD_ADMIN_ID, legacy_actor_id)
      external_id = AdminApiToken.generate_token(AdminApiToken::EXTERNAL_ID_LENGTH)
      AdminApiToken.insert!(
        {
          external_id:,
          actor_user_id: legacy_actor_id,
          token_hash: AdminApiToken.hash_token("legacy-admin-token-#{SecureRandom.uuid}"),
          created_at: Time.current,
          updated_at: Time.current
        }
      )
      AdminApiToken.find_by!(external_id:)
    end
end
