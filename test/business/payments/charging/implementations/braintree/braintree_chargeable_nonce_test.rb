# frozen_string_literal: true

require "test_helper"

class BraintreeChargeableNonceTest < ActiveSupport::TestCase
  # Build a Braintree::Customer instance via the public testing helper —
  # _new is the documented constructor the Braintree gem exposes for tests.
  def build_paypal_customer
    paypal_account = Braintree::PayPalAccount._new(
      Braintree::Configuration.gateway,
      email: "jane.doe@example.com",
      token: "ppToken1"
    )
    customer = Braintree::Customer._new(
      Braintree::Configuration.gateway,
      id: "cust_paypal_1",
      paypal_accounts: [{ email: "jane.doe@example.com", token: "ppToken1" }],
      credit_cards: []
    )
    # _new builds PayPalAccount entries from the hash already; verify and
    # fall back to assignment if needed.
    customer.instance_variable_set(:@paypal_accounts, [paypal_account])
    customer.instance_variable_set(:@credit_cards, [])
    customer
  end

  def build_card_customer
    card = Braintree::CreditCard._new(
      Braintree::Configuration.gateway,
      token: "ccToken1",
      bin: "411111",
      last_4: "1881",
      card_type: "Visa",
      expiration_month: "12",
      expiration_year: "2020",
      unique_number_identifier: "9a09e816d246aac4198e616ca18abe6e",
      country_of_issuance: "United States of America",
      billing_address: nil
    )
    customer = Braintree::Customer._new(
      Braintree::Configuration.gateway,
      id: "cust_card_1",
      paypal_accounts: [],
      credit_cards: []
    )
    customer.instance_variable_set(:@paypal_accounts, [])
    customer.instance_variable_set(:@credit_cards, [card])
    customer
  end

  test "#prepare! raises on invalid chargeable (validation failure)" do
    validation_result = Struct.new(:errors).new([])
    Braintree::Customer.stub(:create!, ->(*) { raise Braintree::ValidationsFailed.new(validation_result) }) do
      chargeable = BraintreeChargeableNonce.new("invalid", nil)
      assert_raises(ChargeProcessorInvalidRequestError) { chargeable.prepare! }
    end
  end

  test "#prepare! raises on already-consumed nonce (validation failure)" do
    validation_result = Struct.new(:errors).new([])
    Braintree::Customer.stub(:create!, ->(*) { raise Braintree::ValidationsFailed.new(validation_result) }) do
      chargeable = BraintreeChargeableNonce.new("fake-consumed-nonce", nil)
      assert_raises(ChargeProcessorInvalidRequestError) { chargeable.prepare! }
    end
  end

  test "#prepare! raises ChargeProcessorUnavailableError when service unavailable" do
    Braintree::Customer.stub(:create!, ->(*) { raise Braintree::ServiceUnavailableError }) do
      chargeable = BraintreeChargeableNonce.new("fake-nonce", nil)
      assert_raises(ChargeProcessorUnavailableError) { chargeable.prepare! }
    end
  end

  test "credit card chargeable: prepare! succeeds and exposes expected card information" do
    Braintree::Customer.stub(:create!, build_card_customer) do
      chargeable = BraintreeChargeableNonce.new("fake-card-nonce", nil)
      assert chargeable.prepare!

      assert_equal "cust_card_1", chargeable.braintree_customer_id
      assert_equal "9a09e816d246aac4198e616ca18abe6e", chargeable.fingerprint
      assert_equal CardType::VISA, chargeable.card_type
      assert_equal "1881", chargeable.last4
      assert_equal "12", chargeable.expiry_month
      assert_equal "2020", chargeable.expiry_year
    end
  end

  test "paypal chargeable: prepare! succeeds and exposes expected account information" do
    Braintree::Customer.stub(:create!, build_paypal_customer) do
      chargeable = BraintreeChargeableNonce.new("fake-paypal-nonce", nil)
      assert chargeable.prepare!

      assert_equal "cust_paypal_1", chargeable.braintree_customer_id
      assert_equal "paypal_jane.doe@example.com", chargeable.fingerprint
      assert_equal CardType::PAYPAL, chargeable.card_type
      assert_nil chargeable.last4
      assert_equal "jane.doe@example.com", chargeable.visual
      assert_nil chargeable.expiry_month
      assert_nil chargeable.expiry_year
    end
  end

  test "#charge_processor_id returns 'braintree'" do
    chargeable = BraintreeChargeableNonce.new("fake-paypal-nonce", nil)
    assert_equal "braintree", chargeable.charge_processor_id
  end
end
