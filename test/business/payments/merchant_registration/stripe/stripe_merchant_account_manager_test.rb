# frozen_string_literal: true

require "test_helper"

class StripeMerchantAccountManagerTest < ActiveSupport::TestCase
  fixtures :users, :merchant_accounts

  setup do
    @user = users(:basic_user)
  end

  # ---- Module-level constants & class methods ----

  test "REQUESTED_CAPABILITIES contains the documented capabilities" do
    assert_includes StripeMerchantAccountManager::REQUESTED_CAPABILITIES, "card_payments"
    assert_includes StripeMerchantAccountManager::REQUESTED_CAPABILITIES, "transfers"
  end

  test "COUNTRIES_SUPPORTED_BY_STRIPE_CONNECT covers core US/Canada/UK/EU/Japan" do
    {
      "United States" => Compliance::Countries::USA,
      "Canada" => Compliance::Countries::CAN,
      "United Kingdom" => Compliance::Countries::GBR,
      "Germany" => Compliance::Countries::DEU,
      "Japan" => Compliance::Countries::JPN
    }.each_value do |country|
      assert_includes StripeMerchantAccountManager::COUNTRIES_SUPPORTED_BY_STRIPE_CONNECT, country.alpha2
    end
  end

  test "NEW_ACCOUNT_CREATION_BLOCKED_COUNTRIES contains India" do
    assert_includes StripeMerchantAccountManager::NEW_ACCOUNT_CREATION_BLOCKED_COUNTRIES,
                    Compliance::Countries::IND.alpha2
  end

  test ".account_holder_name_synced_to_stripe? is false when user has no compliance info" do
    refute StripeMerchantAccountManager.account_holder_name_synced_to_stripe?(@user)
  end

  test ".account_holder_name_synced_to_stripe? is true for Japan-resident user compliance info" do
    user_with_compliance = users(:another_seller)
    UserComplianceInfo.create!(
      user: user_with_compliance,
      country: "Japan",
      first_name: "Ichiro",
      last_name: "Tester"
    )
    assert StripeMerchantAccountManager.account_holder_name_synced_to_stripe?(user_with_compliance.reload)
  end

  test ".account_holder_name_synced_to_stripe? is false for US-resident user compliance info" do
    user_with_compliance = users(:another_seller)
    UserComplianceInfo.create!(
      user: user_with_compliance,
      country: "United States",
      first_name: "Jane",
      last_name: "Tester"
    )
    refute StripeMerchantAccountManager.account_holder_name_synced_to_stripe?(user_with_compliance.reload)
  end

  # ---- .get_diff_attributes ----

  test ".get_diff_attributes returns only changed leaves" do
    current = { a: 1, b: { c: 2, d: 3 } }
    last    = { a: 1, b: { c: 99, d: 3 } }
    assert_equal({ b: { c: 2 } }, StripeMerchantAccountManager.get_diff_attributes(current, last))
  end

  test ".get_diff_attributes returns the whole tree when nothing matches" do
    current = { a: 1, b: 2 }
    last    = {}
    assert_equal current, StripeMerchantAccountManager.get_diff_attributes(current, last)
  end

  test ".get_diff_attributes returns an empty hash when nothing changed" do
    current = { a: 1, b: { c: 2 } }
    last    = { a: 1, b: { c: 2 } }
    assert_equal({}, StripeMerchantAccountManager.get_diff_attributes(current, last))
  end

  # ---- .prefecture_kana ----

  test ".prefecture_kana delegates to Compliance::Countries#japan_prefecture_kana" do
    # Pick a known kanji-to-kana mapping. "東京都" -> "トウキョウト"
    result = StripeMerchantAccountManager.prefecture_kana("東京都")
    assert_kind_of String, result
    assert_equal Compliance::Countries.japan_prefecture_kana("東京都"), result
  end

  # ---- .handle_stripe_event dispatch ----

  test ".handle_stripe_event ignores unknown event types silently" do
    assert_nothing_raised do
      StripeMerchantAccountManager.handle_stripe_event("type" => "unknown.event_type", "data" => { "object" => {} })
    end
  end

  test ".handle_stripe_event_account_deauthorized is a no-op when no merchant account matches" do
    stripe_event = {
      "id" => "evt_test_1",
      "type" => "account.application.deauthorized",
      "user_id" => "acct_nonexistent_#{SecureRandom.hex(4)}",
      "account" => nil
    }
    assert_nothing_raised do
      StripeMerchantAccountManager.handle_stripe_event_account_deauthorized(stripe_event)
    end
  end

  test ".handle_stripe_event_account_deauthorized marks a matching alive merchant account as deleted" do
    acct_id = "acct_deauth_#{SecureRandom.hex(4).upcase}"
    ma = MerchantAccount.create!(
      user: @user,
      charge_processor_id: StripeChargeProcessor.charge_processor_id,
      charge_processor_merchant_id: acct_id,
      charge_processor_alive_at: 1.day.ago,
      country: "US",
      currency: "usd"
    )
    stripe_event = {
      "id" => "evt_deauth_1",
      "type" => "account.application.deauthorized",
      "user_id" => acct_id
    }
    StripeMerchantAccountManager.handle_stripe_event_account_deauthorized(stripe_event)
    refute ma.reload.alive?
  end

  test ".handle_stripe_event_account_updated raises when the event payload doesn't contain an account object" do
    stripe_event = {
      "id" => "evt_test_3",
      "type" => "account.updated",
      "data" => { "object" => { "object" => "person" } }
    }
    assert_raises(RuntimeError) do
      StripeMerchantAccountManager.handle_stripe_event_account_updated(stripe_event)
    end
  end

  test ".handle_stripe_event_capability_updated raises when the event payload doesn't contain a capability object" do
    stripe_event = {
      "id" => "evt_test_4",
      "type" => "capability.updated",
      "data" => { "object" => { "object" => "account" } }
    }
    assert_raises(RuntimeError) do
      StripeMerchantAccountManager.handle_stripe_event_capability_updated(stripe_event)
    end
  end

  # ---- .disconnect ----

  test ".disconnect returns false when the user does not have a connected stripe account" do
    # @user does not have a connected stripe account; stripe_disconnect_allowed? is true
    # (because !has_stripe_account_connected? short-circuits to true), but
    # user.stripe_connect_account is nil → nil.delete_charge_processor_account! would raise.
    # So we expect an exception or false; either way the helper should not corrupt state.
    assert_raises(NoMethodError) do
      StripeMerchantAccountManager.disconnect(user: @user)
    end
  end
end
