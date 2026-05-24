# frozen_string_literal: true

require "test_helper"

class VariantPriceTest < ActiveSupport::TestCase
  def membership_tier
    base_variants(:variant_price_test_tier)
  end

  def standalone_variant
    base_variants(:variant_price_test_standalone_variant)
  end

  test "associations: belongs to a variant" do
    price = VariantPrice.create!(variant: standalone_variant, price_cents: 100, currency: "usd", recurrence: "monthly")
    assert_kind_of Variant, price.variant
  end

  test "validations: requires that the variant is present" do
    price = VariantPrice.create!(variant: standalone_variant, price_cents: 100, currency: "usd", recurrence: "monthly")
    price.variant = nil
    assert_not price.valid?
    assert_includes price.errors.full_messages, "Variant can't be blank"
  end

  test "validations: requires that price_cents is present" do
    price = VariantPrice.create!(variant: standalone_variant, price_cents: 100, currency: "usd", recurrence: "monthly")
    price.price_cents = nil
    assert_not price.valid?
    assert_includes price.errors.full_messages, "Please provide a price for all selected payment options."
  end

  test "validations: requires that currency is present" do
    price = VariantPrice.create!(variant: standalone_variant, price_cents: 100, currency: "usd", recurrence: "monthly")
    price.currency = nil
    assert_not price.valid?
    assert_includes price.errors.full_messages, "Currency can't be blank"
  end

  test "recurrence validation: must be one of the permitted recurrences when present" do
    BasePrice::Recurrence.all.each do |recurrence|
      vp = VariantPrice.new(variant: standalone_variant, price_cents: 100, currency: "usd", recurrence: recurrence)
      assert vp.valid?, "recurrence #{recurrence} expected to be valid: #{vp.errors.full_messages.inspect}"
    end

    invalid = VariantPrice.new(variant: standalone_variant, price_cents: 100, currency: "usd", recurrence: "whenever")
    assert_not invalid.valid?
    assert_includes invalid.errors.full_messages, "Please provide a valid payment option."
  end

  test "recurrence validation: can be blank" do
    vp = VariantPrice.new(variant: standalone_variant, price_cents: 100, currency: "usd", recurrence: nil)
    assert vp.valid?
  end

  test "is_default_recurrence? returns true when recurrence matches product subscription_duration" do
    price = VariantPrice.create!(variant: membership_tier, price_cents: 100, currency: "usd", recurrence: "monthly")
    assert_equal true, price.is_default_recurrence?
  end

  test "is_default_recurrence? returns false when recurrence does not match" do
    price_yearly = VariantPrice.create!(variant: membership_tier, price_cents: 100, currency: "usd", recurrence: "yearly")
    price_nil_recurrence = VariantPrice.create!(variant: membership_tier, price_cents: 100, currency: "usd", recurrence: nil)
    price_non_membership = VariantPrice.create!(variant: standalone_variant, price_cents: 100, currency: "usd", recurrence: "monthly")

    [price_yearly, price_nil_recurrence, price_non_membership].each do |p|
      assert_equal false, p.is_default_recurrence?, "expected #{p.inspect} to NOT be default recurrence"
    end
  end

  test "#price_formatted_without_symbol returns formatted price without a symbol" do
    price = VariantPrice.create!(variant: standalone_variant, price_cents: 299, currency: "usd", recurrence: "monthly")
    assert_equal "2.99", price.price_formatted_without_symbol
  end

  test "#price_formatted_without_symbol returns empty string when price_cents is blank" do
    price = VariantPrice.new(variant: standalone_variant, price_cents: nil, currency: "usd", recurrence: "monthly")
    assert_equal "", price.price_formatted_without_symbol
  end

  test "#suggested_price_formatted_without_symbol returns formatted suggested price without a symbol" do
    price = VariantPrice.create!(variant: standalone_variant, price_cents: 100, currency: "usd", recurrence: "monthly", suggested_price_cents: 299)
    assert_equal "2.99", price.suggested_price_formatted_without_symbol
  end

  test "#suggested_price_formatted_without_symbol returns nil when suggested_price_cents is blank" do
    price = VariantPrice.new(variant: standalone_variant, price_cents: 100, currency: "usd", recurrence: "monthly", suggested_price_cents: nil)
    assert_nil price.suggested_price_formatted_without_symbol
  end
end
