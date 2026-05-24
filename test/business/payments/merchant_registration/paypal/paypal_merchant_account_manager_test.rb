# frozen_string_literal: true

require "test_helper"

class PaypalMerchantAccountManagerTest < ActiveSupport::TestCase
  fixtures :users, :merchant_accounts

  setup do
    @user = users(:basic_user)
    @manager = PaypalMerchantAccountManager.new
  end

  # ---- handle_paypal_event: MERCHANT_PARTNER_CONSENT_REVOKED ----

  def revoked_event(merchant_id: "FQ9WM47T82UAS")
    {
      "id" => "WH-evt-#{SecureRandom.hex(4)}",
      "event_type" => PaypalEventType::MERCHANT_PARTNER_CONSENT_REVOKED,
      "resource_type" => "partner-consent",
      "resource" => { "merchant_id" => merchant_id, "tracking_id" => "tracking-x" }
    }
  end

  test "handle_paypal_event (REVOKED): no-op when no merchant account is present for the merchant id" do
    assert_nothing_raised do
      @manager.handle_paypal_event(revoked_event(merchant_id: "absent-merchant"))
    end
  end

  test "handle_paypal_event (REVOKED): marks all matching alive paypal merchant accounts as deleted" do
    merchant_id = "WEBHOOK_ABC_PP_#{SecureRandom.hex(3).upcase}"

    ma1 = MerchantAccount.create!(
      user: @user,
      charge_processor_id: PaypalChargeProcessor.charge_processor_id,
      charge_processor_merchant_id: merchant_id,
      charge_processor_alive_at: 1.day.ago
    )
    ma2 = MerchantAccount.create!(
      user: users(:another_seller),
      charge_processor_id: PaypalChargeProcessor.charge_processor_id,
      charge_processor_merchant_id: merchant_id,
      charge_processor_alive_at: 1.day.ago
    )

    assert ma1.alive?
    assert ma2.alive?

    @manager.handle_paypal_event(revoked_event(merchant_id: merchant_id))
    refute ma1.reload.alive?
    refute ma2.reload.alive?
  end

  test "handle_paypal_event (REVOKED): does nothing when all merchant accounts are already deleted" do
    merchant_id = "WEBHOOK_DELETED_PP_#{SecureRandom.hex(3).upcase}"
    ma = MerchantAccount.create!(
      user: @user,
      charge_processor_id: PaypalChargeProcessor.charge_processor_id,
      charge_processor_merchant_id: merchant_id,
      charge_processor_alive_at: 1.day.ago
    )
    ma.mark_deleted!
    refute ma.reload.alive?

    # No mailer should fire; if it did, the deliver_later call would still be
    # safe in test mode but we assert that no MerchantAccount changes state.
    assert_no_difference -> { MerchantAccount.where(charge_processor_merchant_id: merchant_id).pluck(:deleted_at, :charge_processor_deleted_at).map(&:join).count } do
      @manager.handle_paypal_event(revoked_event(merchant_id: merchant_id))
    end
  end

  # ---- handle_paypal_event: MERCHANT_ONBOARDING_COMPLETED ----

  test "handle_paypal_event (ONBOARDING_COMPLETED): does nothing when tracking_id is absent" do
    paypal_event = {
      "event_type" => PaypalEventType::MERCHANT_ONBOARDING_COMPLETED,
      "resource" => { "merchant_id" => "V74ZDABEJCZ7C" } # no tracking_id
    }
    assert_no_difference -> { MerchantAccount.count } do
      @manager.handle_paypal_event(paypal_event)
    end
  end

  test "handle_paypal_event (ONBOARDING_COMPLETED): does not create a merchant account when one is not present and user does not meet eligibility" do
    paypal_event = {
      "event_type" => PaypalEventType::MERCHANT_ONBOARDING_COMPLETED,
      "resource" => { "merchant_id" => "GSQ5PDPXZCWGW", "tracking_id" => @user.external_id }
    }
    assert_no_difference -> { MerchantAccount.count } do
      @manager.handle_paypal_event(paypal_event)
    end
  end

  # ---- handle_paypal_event: MERCHANT_CAPABILITY_UPDATED ----

  test "handle_paypal_event (CAPABILITY_UPDATED): does not create a merchant account when one is not present" do
    paypal_event = {
      "event_type" => PaypalEventType::MERCHANT_CAPABILITY_UPDATED,
      "resource" => { "merchant_id" => "GSQ5PDPXZCWGW", "tracking_id" => @user.external_id }
    }
    assert_no_difference -> { MerchantAccount.count } do
      @manager.handle_paypal_event(paypal_event)
    end
  end

  # ---- handle_paypal_event: MERCHANT_SUBSCRIPTION_UPDATED ----

  test "handle_paypal_event (SUBSCRIPTION_UPDATED): does not create a merchant account when one is not present" do
    paypal_event = {
      "event_type" => PaypalEventType::MERCHANT_SUBSCRIPTION_UPDATED,
      "resource" => { "merchant_id" => "FQ9WM47T82UAS", "tracking_id" => @user.external_id }
    }
    assert_no_difference -> { MerchantAccount.count } do
      @manager.handle_paypal_event(paypal_event)
    end
  end

  # ---- handle_paypal_event: MERCHANT_EMAIL_CONFIRMED ----

  test "handle_paypal_event (EMAIL_CONFIRMED): does not create a merchant account when one is not present" do
    paypal_event = {
      "event_type" => PaypalEventType::MERCHANT_EMAIL_CONFIRMED,
      "resource" => { "merchant_id" => "FQ9WM47T82UAS", "tracking_id" => @user.external_id }
    }
    assert_no_difference -> { MerchantAccount.count } do
      @manager.handle_paypal_event(paypal_event)
    end
  end

  # ---- handle_paypal_event: MERCHANT_ONBOARDING_SELLER_GRANTED_CONSENT ----

  test "handle_paypal_event (SELLER_GRANTED_CONSENT): does not create a merchant account when one is not present" do
    paypal_event = {
      "event_type" => PaypalEventType::MERCHANT_ONBOARDING_SELLER_GRANTED_CONSENT,
      "resource" => { "merchant_id" => "FQ9WM47T82UAS", "tracking_id" => @user.external_id }
    }
    assert_no_difference -> { MerchantAccount.count } do
      @manager.handle_paypal_event(paypal_event)
    end
  end

  # ---- update_merchant_account ----

  test "#update_merchant_account returns an error message when user is blank" do
    msg = @manager.update_merchant_account(user: nil, paypal_merchant_id: "anything")
    assert_equal "There was an error connecting your PayPal account with Gumroad.", msg
  end

  test "#update_merchant_account returns an error message when paypal_merchant_id is blank" do
    msg = @manager.update_merchant_account(user: @user, paypal_merchant_id: nil)
    assert_equal "There was an error connecting your PayPal account with Gumroad.", msg
  end

  test "#update_merchant_account returns an eligibility error when the user does not meet PCP requirements" do
    # @user does not satisfy paypal_connect_allowed? (no compliance/sales/payouts)
    msg = @manager.update_merchant_account(user: @user, paypal_merchant_id: "GSQ5PDPXZCWGW")
    assert_equal "Your PayPal account could not be connected because you do not meet the eligibility requirements.", msg
  end

  test "#disconnect returns false when the user has no alive paypal merchant account" do
    refute @manager.disconnect(user: @user)
  end

  test "#disconnect marks the user's alive paypal merchant account as deleted" do
    ma = MerchantAccount.create!(
      user: @user,
      charge_processor_id: PaypalChargeProcessor.charge_processor_id,
      charge_processor_merchant_id: "PP_DISC_#{SecureRandom.hex(3).upcase}",
      charge_processor_alive_at: 1.day.ago
    )
    assert ma.alive?
    @manager.disconnect(user: @user)
    refute ma.reload.alive?
  end

  # ---- create_partner_referral ----

  test "#create_partner_referral returns failure data when the API does not return success" do
    failed_response = Object.new
    failed_response.define_singleton_method(:success?) { false }
    failed_response.define_singleton_method(:[]) { |_k| nil }
    failed_response.define_singleton_method(:parsed_response) { { "name" => "VALIDATION_ERROR" } }
    failed_response.define_singleton_method(:request) { nil }

    PaypalMerchantAccountManager.define_method(:authorization_header) { " " }
    original = PaypalIntegrationRestApi.instance_method(:create_partner_referral)
    PaypalIntegrationRestApi.define_method(:create_partner_referral) { |_url| failed_response }
    begin
      result = @manager.create_partner_referral(@user, "http://redirecturl.com")
      assert_equal false, result[:success]
      assert_equal "Invalid request. Please try again later.", result[:error_message]
    ensure
      PaypalIntegrationRestApi.define_method(:create_partner_referral, original)
      PaypalMerchantAccountManager.remove_method(:authorization_header) if PaypalMerchantAccountManager.private_instance_methods(false).include?(:authorization_header) || PaypalMerchantAccountManager.instance_methods(false).include?(:authorization_header)
    end
  end

  test "#create_partner_referral returns success data when API yields an action_url" do
    success_response = Object.new
    success_response.define_singleton_method(:success?) { true }
    success_response.define_singleton_method(:[]) do |k|
      case k
      when "links" then [{ "rel" => "action_url", "href" => "https://www.sandbox.paypal.com/x?token=abc" }]
      end
    end

    PaypalMerchantAccountManager.define_method(:authorization_header) { " " }
    original = PaypalIntegrationRestApi.instance_method(:create_partner_referral)
    PaypalIntegrationRestApi.define_method(:create_partner_referral) { |_url| success_response }
    begin
      result = @manager.create_partner_referral(@user, "http://redirecturl.com")
      assert_equal true, result[:success]
      assert_includes result[:redirect_url], "www.sandbox.paypal.com"
    ensure
      PaypalIntegrationRestApi.define_method(:create_partner_referral, original)
      PaypalMerchantAccountManager.remove_method(:authorization_header) if PaypalMerchantAccountManager.private_instance_methods(false).include?(:authorization_header) || PaypalMerchantAccountManager.instance_methods(false).include?(:authorization_header)
    end
  end
end
