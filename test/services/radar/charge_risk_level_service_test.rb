# frozen_string_literal: true

require "test_helper"

class Radar::ChargeRiskLevelServiceTest < ActiveSupport::TestCase
  setup do
    @cache_token = SecureRandom.hex(8)
  end

  test ".fetch returns nil for purchases without stripe_transaction_id" do
    purchase = prepared_purchase(:named_seller_call_purchase)
    purchase.update_columns(stripe_transaction_id: nil)

    assert_nil Radar::ChargeRiskLevelService.fetch(purchase)
  end

  test ".fetch returns nil for non-Stripe purchases" do
    purchase = prepared_purchase(:named_seller_call_purchase)
    purchase.update_columns(charge_processor_id: "paypal")

    assert_nil Radar::ChargeRiskLevelService.fetch(purchase)
  end

  test ".fetch fetches risk level from Stripe and caches it" do
    purchase = prepared_purchase(:named_seller_call_purchase)
    calls = []
    stripe_charge = Stripe::Charge.construct_from(outcome: { risk_level: "elevated" })

    Stripe::Charge.stub(:retrieve, ->(*args) { calls << args; stripe_charge }) do
      assert_equal "elevated", Radar::ChargeRiskLevelService.fetch(purchase)
      assert_equal "elevated", Radar::ChargeRiskLevelService.fetch(purchase)
    end

    assert_equal [[purchase.stripe_transaction_id]], calls
  end

  test ".fetch returns nil when the charge has no risk assessment" do
    purchase = prepared_purchase(:named_seller_call_purchase)
    calls = []
    stripe_charge = Stripe::Charge.construct_from(outcome: nil)

    Stripe::Charge.stub(:retrieve, ->(*args) { calls << args; stripe_charge }) do
      assert_nil Radar::ChargeRiskLevelService.fetch(purchase)
    end

    assert_equal [[purchase.stripe_transaction_id]], calls
  end

  test ".fetch fetches from the connect account" do
    purchase = prepared_purchase(:named_seller_call_purchase)
    merchant_account = merchant_accounts(:radar_stripe_connect_account)
    purchase.update_columns(merchant_account_id: merchant_account.id)
    calls = []
    stripe_charge = Stripe::Charge.construct_from(outcome: { risk_level: "highest" })

    Stripe::Charge.stub(:retrieve, ->(*args) { calls << args; stripe_charge }) do
      assert_equal "highest", Radar::ChargeRiskLevelService.fetch(purchase.reload)
    end

    assert_equal [[{ id: purchase.stripe_transaction_id }, { stripe_account: merchant_account.charge_processor_merchant_id }]], calls
  end

  test ".fetch falls back to Gumroad account on connect account error" do
    purchase = prepared_purchase(:named_seller_call_purchase)
    merchant_account = merchant_accounts(:radar_stripe_connect_account)
    purchase.update_columns(merchant_account_id: merchant_account.id)
    calls = []
    stripe_charge = Stripe::Charge.construct_from(outcome: { risk_level: "normal" })

    Stripe::Charge.stub(:retrieve, ->(*args) {
      calls << args
      raise StandardError, "Not found" if args.first.is_a?(Hash)

      stripe_charge
    }) do
      assert_equal "normal", Radar::ChargeRiskLevelService.fetch(purchase.reload)
    end

    assert_equal [
      [{ id: purchase.stripe_transaction_id }, { stripe_account: merchant_account.charge_processor_merchant_id }],
      [purchase.stripe_transaction_id],
    ], calls
  end

  test ".fetch returns nil on Stripe error" do
    purchase = prepared_purchase(:named_seller_call_purchase)

    Stripe::Charge.stub(:retrieve, ->(*_args) { raise Stripe::StripeError, "API error" }) do
      assert_nil Radar::ChargeRiskLevelService.fetch(purchase)
    end
  end

  test ".fetch_bulk fetches risk levels and skips non-Stripe purchases" do
    purchase = prepared_purchase(:named_seller_call_purchase, stripe_transaction_id: "ch_radar_one_#{@cache_token}")
    purchase2 = prepared_purchase(:another_seller_call_purchase, stripe_transaction_id: "ch_radar_two_#{@cache_token}")
    non_stripe = prepared_purchase(:audience_purchase)
    non_stripe.update_columns(stripe_transaction_id: nil)
    charges = {
      "ch_radar_one_#{@cache_token}" => Stripe::Charge.construct_from(outcome: { risk_level: "normal" }),
      "ch_radar_two_#{@cache_token}" => Stripe::Charge.construct_from(outcome: { risk_level: "elevated" }),
    }

    Stripe::Charge.stub(:retrieve, ->(stripe_transaction_id) { charges.fetch(stripe_transaction_id) }) do
      results = Radar::ChargeRiskLevelService.fetch_bulk([purchase, purchase2, non_stripe])

      assert_equal "normal", results[purchase.id]
      assert_equal "elevated", results[purchase2.id]
      assert_not results.key?(non_stripe.id)
    end
  end

  test ".fetch_bulk caches nil results and does not re-fetch from Stripe" do
    purchase = prepared_purchase(:named_seller_call_purchase)
    calls = []
    charge = Stripe::Charge.construct_from(outcome: { risk_level: nil })

    Stripe::Charge.stub(:retrieve, ->(*args) { calls << args; charge }) do
      assert_nil Radar::ChargeRiskLevelService.fetch_bulk([purchase])[purchase.id]
      assert_nil Radar::ChargeRiskLevelService.fetch_bulk([purchase])[purchase.id]
    end

    assert_equal [[purchase.stripe_transaction_id]], calls
  end

  test ".fetch_bulk caches nil results when charge outcome is nil" do
    purchase = prepared_purchase(:named_seller_call_purchase)
    calls = []
    charge = Stripe::Charge.construct_from(outcome: nil)

    Stripe::Charge.stub(:retrieve, ->(*args) { calls << args; charge }) do
      assert_nil Radar::ChargeRiskLevelService.fetch_bulk([purchase])[purchase.id]
      assert_nil Radar::ChargeRiskLevelService.fetch_bulk([purchase])[purchase.id]
    end

    assert_equal [[purchase.stripe_transaction_id]], calls
  end

  test ".fetch_bulk uses cache for already-fetched purchases" do
    purchase = prepared_purchase(:named_seller_call_purchase)
    calls = []
    charge = Stripe::Charge.construct_from(outcome: { risk_level: "highest" })

    Stripe::Charge.stub(:retrieve, ->(*args) { calls << args; charge }) do
      Radar::ChargeRiskLevelService.fetch_bulk([purchase])
      results = Radar::ChargeRiskLevelService.fetch_bulk([purchase])

      assert_equal "highest", results[purchase.id]
    end

    assert_equal [[purchase.stripe_transaction_id]], calls
  end

  test ".fetch_bulk deduplicates purchases sharing the same stripe_transaction_id" do
    shared_transaction_id = "ch_shared_radar_#{@cache_token}"
    purchase = prepared_purchase(:named_seller_call_purchase, stripe_transaction_id: shared_transaction_id)
    duplicate = prepared_purchase(:another_seller_call_purchase, stripe_transaction_id: shared_transaction_id)
    calls = []
    charge = Stripe::Charge.construct_from(outcome: { risk_level: "elevated" })

    Stripe::Charge.stub(:retrieve, ->(*args) { calls << args; charge }) do
      results = Radar::ChargeRiskLevelService.fetch_bulk([purchase, duplicate])

      assert_equal "elevated", results[purchase.id]
      assert_equal "elevated", results[duplicate.id]
    end

    assert_equal [[shared_transaction_id]], calls
  end

  private
    def prepared_purchase(fixture_name, stripe_transaction_id: nil)
      purchase = purchases(fixture_name)
      purchase.update_columns(
        stripe_transaction_id: stripe_transaction_id || "ch_radar_#{purchase.id}_#{@cache_token}",
        charge_processor_id: StripeChargeProcessor.charge_processor_id,
        merchant_account_id: nil
      )
      purchase.reload
    end
end
