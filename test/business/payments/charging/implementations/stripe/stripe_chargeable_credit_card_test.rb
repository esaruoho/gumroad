# frozen_string_literal: true

require "test_helper"

class StripeChargeableCreditCardTest < ActiveSupport::TestCase
  # Use stripe-mock for any real Stripe API calls.
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

  def build_chargeable(merchant_account: nil, payment_method_id: "pm_test_123", customer_id: "cus_test_abc")
    StripeChargeableCreditCard.new(
      merchant_account,
      customer_id,
      payment_method_id,
      "fp_abc",
      nil, nil,
      "4242", 16, "**** **** **** 4242",
      12, 2030, CardType::VISA, "US", "12345"
    )
  end

  test "charge_processor_id returns stripe" do
    assert_equal "stripe", build_chargeable.charge_processor_id
  end

  test "funding_type is nil" do
    assert_nil build_chargeable.funding_type
  end

  test "exposes initializer-supplied attributes" do
    c = build_chargeable
    assert_equal "fp_abc", c.fingerprint
    assert_equal "pm_test_123", c.payment_method_id
    assert_equal "4242", c.last4
    assert_equal 16, c.number_length
    assert_equal "**** **** **** 4242", c.visual
    assert_equal 12, c.expiry_month
    assert_equal 2030, c.expiry_year
    assert_equal CardType::VISA, c.card_type
    assert_equal "US", c.country
    assert_equal "12345", c.zip_code
  end

  test "#reusable_token! returns the customer id ignoring its argument" do
    c = build_chargeable(customer_id: "cus_xyz")
    user = users(:basic_user)
    assert_equal "cus_xyz", c.reusable_token!(user)
    assert_equal "cus_xyz", c.reusable_token!(nil)
  end

  test "#stripe_charge_params returns customer + payment_method when no merchant account" do
    c = build_chargeable(merchant_account: nil)
    assert_equal({ customer: "cus_test_abc", payment_method: "pm_test_123" }, c.stripe_charge_params)
  end

  test "#stripe_charge_params returns customer + payment_method when merchant is gumroad stripe (not connect)" do
    gumroad = merchant_accounts(:forfeit_gumroad_stripe_account)
    refute gumroad.is_a_stripe_connect_account?
    c = build_chargeable(merchant_account: gumroad)
    assert_equal({ customer: "cus_test_abc", payment_method: "pm_test_123" }, c.stripe_charge_params)
  end

  test "#requires_mandate? is true only for Indian cards" do
    c_us = StripeChargeableCreditCard.new(nil, "cus", "pm", "fp",
      nil, nil, "4242", 16, "vv", 1, 2030, CardType::VISA, "US")
    refute c_us.requires_mandate?

    c_in = StripeChargeableCreditCard.new(nil, "cus", "pm", "fp",
      nil, nil, "4242", 16, "vv", 1, 2030, CardType::VISA, "IN")
    assert c_in.requires_mandate?
  end

  test "#prepare! is a no-op when payment_method_id already present and no merchant account" do
    c = build_chargeable
    assert_equal true, c.prepare!
    assert_equal "pm_test_123", c.payment_method_id
  end

  test "#prepare! retrieves customer's default_source when payment_method_id is missing" do
    # Stripe-mock returns a Customer with default_source. Verify we end up
    # with a non-nil payment_method_id after prepare!.
    c = StripeChargeableCreditCard.new(
      nil, "cus_required", nil, "fp",
      nil, nil, "4242", 16, "vv", 12, 2030, CardType::VISA, "US"
    )
    c.prepare!
    # stripe-mock returns deterministic default_source or first PM listing —
    # in either case, payment_method_id must be set after prepare!.
    assert_not_nil c.payment_method_id
  end
end
