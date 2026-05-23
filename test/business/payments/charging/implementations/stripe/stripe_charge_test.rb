# frozen_string_literal: true

require "test_helper"

class StripeChargeTest < ActiveSupport::TestCase
  AMOUNT_CENTS = 1_00
  APPLICATION_FEE = 50
  DEST_CURRENCY = Currency::CAD

  def basic_charge_hash(overrides = {})
    {
      id: "ch_basic",
      status: "succeeded",
      refunded: false,
      dispute: nil,
      currency: Currency::USD,
      amount: AMOUNT_CENTS,
      destination: nil,
      payment_method: "pm_test_basic",
      payment_method_details: {
        card: {
          fingerprint: "fp_basic",
          last4: "4242",
          brand: "visa",
          exp_month: 12,
          exp_year: 2030,
          country: "US",
          checks: { address_postal_code_check: nil }
        }
      },
      billing_details: { address: { postal_code: nil } },
      outcome: { risk_level: "normal" }
    }.merge(overrides).with_indifferent_access
  end

  def basic_balance_transaction
    {
      currency: Currency::USD,
      amount: AMOUNT_CENTS,
      net: AMOUNT_CENTS - 30,
      fee_details: [{ type: "stripe_fee", currency: Currency::USD, amount: 30 }]
    }
  end

  # --- Base processor charge shared behavior ---

  test "#[] gives access to getting attributes" do
    subject = StripeCharge.new(basic_charge_hash, basic_balance_transaction, nil, nil, nil)
    subject.id = "charge-id"
    assert_equal "charge-id", subject[:id]
  end

  test "has a flow_of_funds with issued, settled, gumroad amounts" do
    subject = StripeCharge.new(basic_charge_hash, basic_balance_transaction, nil, nil, nil)
    fof = subject.flow_of_funds
    assert fof.present?
    assert fof.issued_amount.present?
    assert fof.settled_amount.present?
    assert fof.gumroad_amount.present?
  end

  # --- Initialize / basic stripe charge ---

  test "initialize sets charge_processor_id to 'stripe'" do
    s = StripeCharge.new(basic_charge_hash, basic_balance_transaction, nil, nil, nil)
    assert_equal "stripe", s.charge_processor_id
  end

  test "initialize sets id, refunded, fee, fee_currency from balance transaction" do
    s = StripeCharge.new(basic_charge_hash, basic_balance_transaction, nil, nil, nil)
    assert_equal "ch_basic", s.id
    assert_equal false, s.refunded
    assert_equal 30, s.fee
    assert_equal Currency::USD, s.fee_currency
  end

  test "initialize sets card details" do
    s = StripeCharge.new(basic_charge_hash, basic_balance_transaction, nil, nil, nil)
    assert_equal "fp_basic", s.card_fingerprint
    assert_equal "pm_test_basic", s.card_instance_id
    assert_equal "4242", s.card_last4
    assert_equal 16, s.card_number_length
    assert_equal 12, s.card_expiry_month
    assert_equal 2030, s.card_expiry_year
    assert_nil s.card_zip_code
    assert_equal "visa", s.card_type
    assert_equal "US", s.card_country
    assert_nil s.zip_check_result
  end

  test "initialize sets risk_level" do
    s = StripeCharge.new(basic_charge_hash, basic_balance_transaction, nil, nil, nil)
    assert_equal "normal", s.risk_level
  end

  test "simple flow of funds (no destination)" do
    s = StripeCharge.new(basic_charge_hash, basic_balance_transaction, nil, nil, nil)
    fof = s.flow_of_funds
    assert_equal Currency::USD, fof.issued_amount.currency
    assert_equal AMOUNT_CENTS, fof.issued_amount.cents
    assert_equal Currency::USD, fof.settled_amount.currency
    assert_equal AMOUNT_CENTS, fof.settled_amount.cents
    assert_equal Currency::USD, fof.gumroad_amount.currency
    assert_equal AMOUNT_CENTS, fof.gumroad_amount.cents
    assert_nil fof.merchant_account_gross_amount
    assert_nil fof.merchant_account_net_amount
  end

  test "initializes correctly without the stripe fee info" do
    bt = basic_balance_transaction
    bt[:fee_details] = []
    s = StripeCharge.new(basic_charge_hash, bt, nil, nil, nil)
    assert_nil s.fee
    assert_nil s.fee_currency
  end

  test "with pass zip check sets zip_check_result true" do
    ch = basic_charge_hash
    ch[:payment_method_details][:card][:checks][:address_postal_code_check] = "pass"
    s = StripeCharge.new(ch, basic_balance_transaction, nil, nil, nil)
    assert_equal true, s.zip_check_result
  end

  test "destination charge with nil destination payment balance transaction returns nil flow_of_funds" do
    charge = basic_charge_hash(destination: "acct_test_456")
    bt = basic_balance_transaction
    s = StripeCharge.new(charge, bt, nil, nil, { amount: 50 })
    assert_nil s.flow_of_funds
  end

  # --- Destination/managed-account charge (transfer_data based) ---

  test "flow_of_funds for managed account charge (transfer_data) computes amounts" do
    charge = basic_charge_hash(destination: "acct_mgr")
    bt = basic_balance_transaction
    dest_payment_bt = { currency: DEST_CURRENCY, amount: AMOUNT_CENTS - APPLICATION_FEE, net: AMOUNT_CENTS - APPLICATION_FEE - 5 }
    dest_transfer = { amount: AMOUNT_CENTS - APPLICATION_FEE }

    s = StripeCharge.new(charge, bt, nil, dest_payment_bt, dest_transfer)
    fof = s.flow_of_funds

    assert_equal Currency::USD, fof.issued_amount.currency
    assert_equal AMOUNT_CENTS, fof.issued_amount.cents

    assert_equal Currency::USD, fof.settled_amount.currency
    assert_equal AMOUNT_CENTS, fof.settled_amount.cents

    assert_equal Currency::USD, fof.gumroad_amount.currency
    assert_equal AMOUNT_CENTS - (AMOUNT_CENTS - APPLICATION_FEE), fof.gumroad_amount.cents

    assert_equal DEST_CURRENCY, fof.merchant_account_gross_amount.currency
    assert_equal AMOUNT_CENTS - APPLICATION_FEE, fof.merchant_account_gross_amount.cents

    assert_equal DEST_CURRENCY, fof.merchant_account_net_amount.currency
    assert_equal AMOUNT_CENTS - APPLICATION_FEE - 5, fof.merchant_account_net_amount.cents
  end

  test "flow_of_funds for managed account charge with application_fee_balance_transaction (old style)" do
    charge = basic_charge_hash(destination: "acct_mgr")
    bt = basic_balance_transaction
    app_fee_bt = { currency: Currency::USD, amount: APPLICATION_FEE }
    dest_payment_bt = { currency: DEST_CURRENCY, amount: AMOUNT_CENTS - APPLICATION_FEE, net: AMOUNT_CENTS - APPLICATION_FEE - 5 }

    s = StripeCharge.new(charge, bt, app_fee_bt, dest_payment_bt, nil)
    fof = s.flow_of_funds

    assert_equal Currency::USD, fof.gumroad_amount.currency
    assert_equal APPLICATION_FEE, fof.gumroad_amount.cents

    assert_equal DEST_CURRENCY, fof.merchant_account_gross_amount.currency
    assert_equal AMOUNT_CENTS - APPLICATION_FEE, fof.merchant_account_gross_amount.cents
  end
end
