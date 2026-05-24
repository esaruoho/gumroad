# frozen_string_literal: true

require "test_helper"

class PaypalChargeProcessorTest < ActiveSupport::TestCase
  test ".charge_processor_id is 'paypal'" do
    assert_equal "paypal", PaypalChargeProcessor.charge_processor_id
  end

  test "#get_chargeable_for_params returns PaypalChargeable for billing_agreement_id" do
    chargeable = PaypalChargeProcessor.new.get_chargeable_for_params(
      { billing_agreement_id: "B-AGR123", visual: "buyer@example.com", card_country: "US" },
      nil
    )
    assert_instance_of PaypalChargeable, chargeable
    assert_equal "B-AGR123", chargeable.fingerprint
    assert_equal "buyer@example.com", chargeable.email
    assert_equal "US", chargeable.country
  end

  test "#get_chargeable_for_params returns PaypalApprovedOrderChargeable for paypal_order_id" do
    chargeable = PaypalChargeProcessor.new.get_chargeable_for_params(
      { paypal_order_id: "ORD-12345", visual: "buyer@example.com", card_country: "GB" },
      nil
    )
    assert_instance_of PaypalApprovedOrderChargeable, chargeable
    assert_equal "ORD-12345", chargeable.fingerprint
  end

  test "#get_chargeable_for_params returns nil when neither id is provided" do
    chargeable = PaypalChargeProcessor.new.get_chargeable_for_params({}, nil)
    assert_nil chargeable
  end

  test "#get_chargeable_for_data always returns a PaypalChargeable" do
    chargeable = PaypalChargeProcessor.new.get_chargeable_for_data(
      "B-token", nil, nil, nil, nil, nil, nil, "buyer@example.com",
      nil, nil, nil, "FR"
    )
    assert_instance_of PaypalChargeable, chargeable
    assert_equal "B-token", chargeable.fingerprint
    assert_equal "buyer@example.com", chargeable.email
    assert_equal "FR", chargeable.country
  end

  test ".tax_cents returns gumroad_tax_cents when Gumroad is responsible" do
    purchase = Purchase.new
    purchase.define_singleton_method(:gumroad_responsible_for_tax?) { true }
    purchase.define_singleton_method(:gumroad_tax_cents) { 17 }
    assert_equal 17, PaypalChargeProcessor.tax_cents(purchase)
  end

  test ".tax_cents returns tax_cents when tax was excluded from price" do
    purchase = Purchase.new
    purchase.define_singleton_method(:gumroad_responsible_for_tax?) { false }
    purchase.define_singleton_method(:was_tax_excluded_from_price) { true }
    purchase.define_singleton_method(:tax_cents) { 12 }
    assert_equal 12, PaypalChargeProcessor.tax_cents(purchase)
  end

  test ".tax_cents returns 0 when tax is included in price" do
    purchase = Purchase.new
    purchase.define_singleton_method(:gumroad_responsible_for_tax?) { false }
    purchase.define_singleton_method(:was_tax_excluded_from_price) { false }
    assert_equal 0, PaypalChargeProcessor.tax_cents(purchase)
  end

  test ".price_cents subtracts shipping_cents from price_cents" do
    purchase = Purchase.new
    purchase.define_singleton_method(:price_cents) { 1_500 }
    purchase.define_singleton_method(:shipping_cents) { 150 }
    purchase.define_singleton_method(:was_tax_excluded_from_price) { false }
    assert_equal 1_350, PaypalChargeProcessor.price_cents(purchase)
  end

  test ".price_cents also subtracts tax when tax is excluded from price" do
    purchase = Purchase.new
    purchase.define_singleton_method(:price_cents) { 1_500 }
    purchase.define_singleton_method(:shipping_cents) { 150 }
    purchase.define_singleton_method(:was_tax_excluded_from_price) { true }
    purchase.define_singleton_method(:tax_cents) { 75 }
    assert_equal 1_275, PaypalChargeProcessor.price_cents(purchase)
  end

  test ".formatted_amount_for_paypal returns dollars-style decimal for USD" do
    amount = PaypalChargeProcessor.formatted_amount_for_paypal(1_50, "USD")
    assert_equal 1.5, amount.to_f
    refute_kind_of Integer, amount
  end

  test ".formatted_amount_for_paypal returns whole-units integer for JPY/HUF/TWD" do
    %w[JPY HUF TWD].each do |c|
      amount = PaypalChargeProcessor.formatted_amount_for_paypal(150_00, c)
      assert_kind_of Integer, amount
    end
  end

  test ".format_money returns 0 for blank input" do
    assert_equal 0, PaypalChargeProcessor.format_money(nil, "USD")
    assert_equal 0, PaypalChargeProcessor.format_money("", "USD")
  end
end
