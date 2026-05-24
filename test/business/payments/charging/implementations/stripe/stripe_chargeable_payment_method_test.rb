# frozen_string_literal: true

require "test_helper"

class StripeChargeablePaymentMethodTest < ActiveSupport::TestCase
  setup do
    @orig_api_base = Stripe.api_base
    @orig_api_key = Stripe.api_key
    Stripe.api_base = "http://127.0.0.1:12111"
    Stripe.api_key = "sk_test_xxx"
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  teardown do
    Stripe.api_base = @orig_api_base
    Stripe.api_key = @orig_api_key
  end

  def create_stripe_pm
    Stripe::PaymentMethod.create(
      type: "card",
      card: { number: "4242424242424242", exp_month: 12, exp_year: 2050, cvc: "123" },
      billing_details: { address: { postal_code: "12345" } }
    )
  end

  test "charge_processor_id returns stripe" do
    pm = create_stripe_pm
    c = StripeChargeablePaymentMethod.new(pm.id, zip_code: "12345", product_permalink: nil)
    assert_equal "stripe", c.charge_processor_id
  end

  test "#prepare! retrieves the payment method from Stripe (no merchant account)" do
    pm = create_stripe_pm
    c = StripeChargeablePaymentMethod.new(pm.id, zip_code: "12345", product_permalink: nil)
    assert_equal true, c.prepare!
    # Side effects: card is now retrievable
    assert_equal "4242", c.last4
  end

  test "#fingerprint, #last4, #card_type, #expiry_*, #country populated after prepare!" do
    pm = create_stripe_pm
    c = StripeChargeablePaymentMethod.new(pm.id, zip_code: "12345", product_permalink: nil)
    c.prepare!
    assert_not_nil c.fingerprint
    assert_equal "4242", c.last4
    assert_equal 16, c.number_length
    assert_equal "**** **** **** 4242", c.visual
    assert_kind_of Integer, c.expiry_month
    assert_kind_of Integer, c.expiry_year
    assert_equal CardType::VISA, c.card_type
    assert_not_nil c.country
  end

  test "#zip_code falls through to initializer arg before prepare!" do
    pm_id = "pm_unfetched"
    c = StripeChargeablePaymentMethod.new(pm_id, zip_code: "99999", product_permalink: nil)
    assert_equal "99999", c.zip_code
  end

  test "#reusable_token! creates a new Stripe customer when none cached" do
    pm = create_stripe_pm
    c = StripeChargeablePaymentMethod.new(pm.id, zip_code: "12345", product_permalink: nil)
    user = users(:basic_user)
    token = c.reusable_token!(user)
    # stripe-mock returns a deterministic customer id (e.g. "cus_xxx")
    assert_match(/\Acus_/, token)
    # Cached for subsequent calls
    assert_equal token, c.reusable_token!(user)
  end

  test "#reusable_token! returns the pre-existing customer_id without creating a new one" do
    pm_id = "pm_test"
    c = StripeChargeablePaymentMethod.new(
      pm_id, customer_id: "cus_already",
      zip_code: "12345", product_permalink: nil
    )
    assert_equal "cus_already", c.reusable_token!(nil)
  end

  test "#stripe_charge_params returns customer + payment_method when not connect" do
    pm = create_stripe_pm
    c = StripeChargeablePaymentMethod.new(
      pm.id, customer_id: "cus_authenticated",
      zip_code: "12345", product_permalink: nil
    )
    c.prepare!
    assert_equal({ customer: "cus_authenticated", payment_method: pm.id }, c.stripe_charge_params)
  end

  test "#stripe_charge_params customer_id from initializer takes precedence over PM's customer" do
    pm = create_stripe_pm
    c = StripeChargeablePaymentMethod.new(
      pm.id, customer_id: "cus_authenticated",
      stripe_setup_intent_id: "seti_123",
      zip_code: "12345", product_permalink: nil
    )
    c.prepare!
    assert_equal "cus_authenticated", c.stripe_charge_params[:customer]
  end

  test "#requires_mandate? mirrors card country" do
    pm = create_stripe_pm
    c = StripeChargeablePaymentMethod.new(pm.id, zip_code: "12345", product_permalink: nil)
    c.prepare!
    assert_equal (c.country == "IN"), c.requires_mandate?
  end

  test "#stripe_setup_intent_id and #stripe_payment_intent_id exposed verbatim" do
    c = StripeChargeablePaymentMethod.new(
      "pm_test", stripe_setup_intent_id: "seti_abc", stripe_payment_intent_id: "pi_abc",
      zip_code: nil, product_permalink: nil
    )
    assert_equal "seti_abc", c.stripe_setup_intent_id
    assert_equal "pi_abc", c.stripe_payment_intent_id
  end
end
