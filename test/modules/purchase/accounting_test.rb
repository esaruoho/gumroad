# frozen_string_literal: true

require "test_helper"

class PurchaseAccountingTest < ActiveSupport::TestCase
  def purchase
    @purchase ||= purchases(:named_seller_call_purchase)
  end

  test "#price_dollars returns price_cents in dollars" do
    purchase.define_singleton_method(:price_cents) { 1234 }
    assert_in_delta 12.34, purchase.price_dollars
  end

  test "#variant_extra_cost_dollars returns variant_extra_cost in dollars" do
    purchase.define_singleton_method(:variant_extra_cost) { 1234 }
    assert_in_delta 12.34, purchase.variant_extra_cost_dollars
  end

  test "#tax_dollars returns tax_cents in dollars" do
    purchase.define_singleton_method(:gumroad_tax_cents) { 0 }
    purchase.define_singleton_method(:tax_cents) { 1234 }
    assert_in_delta 12.34, purchase.tax_dollars
  end

  test "#tax_dollars returns gumroad_tax_cents in dollars if present" do
    purchase.define_singleton_method(:gumroad_tax_cents) { 5678 }
    purchase.define_singleton_method(:tax_cents) { 0 }
    assert_in_delta 56.78, purchase.tax_dollars
  end

  test "#shipping_dollars returns shipping_cents in dollars" do
    purchase.define_singleton_method(:shipping_cents) { 1234 }
    assert_in_delta 12.34, purchase.shipping_dollars
  end

  test "#fee_dollars returns fee_cents in dollars" do
    purchase.define_singleton_method(:fee_cents) { 1234 }
    assert_in_delta 12.34, purchase.fee_dollars
  end

  test "#processor_fee_dollars returns processor_fee_cents in dollars" do
    purchase.define_singleton_method(:processor_fee_cents) { 1234 }
    assert_in_delta 12.34, purchase.processor_fee_dollars
  end

  test "#affiliate_credit_dollars returns affiliate_credit_cents in dollars" do
    purchase.define_singleton_method(:affiliate_credit_cents) { 1234 }
    assert_in_delta 12.34, purchase.affiliate_credit_dollars
  end

  test "#net_total returns price_cents - fee_cents in dollars" do
    purchase.define_singleton_method(:price_cents) { 1234 }
    purchase.define_singleton_method(:fee_cents) { 1126 }
    assert_in_delta 1.08, purchase.net_total
  end

  test "#sub_total returns price_cents - tax_cents - shipping_cents in dollars" do
    purchase.define_singleton_method(:price_cents) { 1234 }
    purchase.define_singleton_method(:tax_cents) { 78 }
    purchase.define_singleton_method(:shipping_cents) { 399 }
    assert_in_delta 7.57, purchase.sub_total
  end

  test "#amount_refunded_dollars returns amount_refunded_cents in dollars" do
    purchase.define_singleton_method(:amount_refunded_cents) { 1234 }
    assert_in_delta 12.34, purchase.amount_refunded_dollars
  end
end
