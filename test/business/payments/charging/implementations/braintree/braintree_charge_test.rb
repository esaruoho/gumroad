# frozen_string_literal: true

require "test_helper"

class BraintreeChargeTest < ActiveSupport::TestCase
  # Plain stubs for braintree transaction shapes used by BraintreeCharge.
  PaypalDetails = Struct.new(:capture_id, keyword_init: true)
  CreditCardDetails = Struct.new(
    :token,
    :last_4,
    :card_type,
    :expiration_month,
    :expiration_year,
    :country_of_issuance,
    keyword_init: true
  )
  FakeBraintreeCharge = Struct.new(
    :id,
    :status,
    :refunded?,
    :amount,
    :credit_card_details,
    :paypal_details,
    keyword_init: true
  )

  setup do
    # Short-circuit the PayPal SDK call so we don't hit network in any test
    # that runs with load_extra_details: true.
    BraintreeCharge.define_method(:load_details_from_paypal) { |_| nil }
  end

  teardown do
    if BraintreeCharge.private_instance_methods(false).include?(:load_details_from_paypal) ||
       BraintreeCharge.instance_methods(false).include?(:load_details_from_paypal)
      BraintreeCharge.remove_method(:load_details_from_paypal)
    end
  end

  test "loads card details for a paypal account (no credit card data) with extra details" do
    cc_details = CreditCardDetails.new(
      token: "ccTok123",
      last_4: nil,
      card_type: nil,
      expiration_month: nil,
      expiration_year: nil,
      country_of_issuance: nil
    )
    txn = FakeBraintreeCharge.new(
      id: "txn123",
      status: "settled",
      refunded?: false,
      amount: 100.0,
      credit_card_details: cc_details,
      paypal_details: PaypalDetails.new(capture_id: "paypal_capture_id")
    )

    paypal_payment_method = Braintree::PayPalAccount._new(
      Braintree::Configuration.gateway,
      email: "jane.doe@example.com",
      token: "ccTok123"
    )

    Braintree::PaymentMethod.stub(:find, paypal_payment_method) do
      charge = BraintreeCharge.new(txn, load_extra_details: true)

      assert_equal "ccTok123", charge.card_instance_id
      assert_nil charge.card_last4
      assert_equal CardType::UNKNOWN, charge.card_type
      assert_nil charge.card_number_length
      assert_nil charge.card_expiry_month
      assert_nil charge.card_expiry_year
      assert_nil charge.card_country
      assert_nil charge.card_zip_code
      assert_equal "paypal_jane.doe@example.com", charge.card_fingerprint
    end
  end

  test "has a simple flow of funds" do
    txn = FakeBraintreeCharge.new(
      id: "txn123",
      status: "settled",
      refunded?: false,
      amount: 100.0,
      credit_card_details: nil,
      paypal_details: nil
    )
    charge = BraintreeCharge.new(txn, load_extra_details: false)

    fof = charge.flow_of_funds
    assert_equal Currency::USD, fof.issued_amount.currency
    assert_equal 100_00, fof.issued_amount.cents
    assert_equal Currency::USD, fof.settled_amount.currency
    assert_equal 100_00, fof.settled_amount.cents
    assert_equal Currency::USD, fof.gumroad_amount.currency
    assert_equal 100_00, fof.gumroad_amount.cents
    assert_nil fof.merchant_account_gross_amount
    assert_nil fof.merchant_account_net_amount
  end

  test "charge_processor_id is braintree" do
    txn = FakeBraintreeCharge.new(
      id: "x", status: "settled", refunded?: false, amount: 1.0,
      credit_card_details: nil, paypal_details: nil
    )
    charge = BraintreeCharge.new(txn, load_extra_details: false)
    assert_equal "braintree", charge.charge_processor_id
  end
end
