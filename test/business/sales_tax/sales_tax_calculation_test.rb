# frozen_string_literal: true

require "test_helper"

class SalesTaxCalculationTest < ActiveSupport::TestCase
  test "returns a valid object for the zero tax helper" do
    taxation_info = SalesTaxCalculation.zero_tax(100)

    assert_equal 100, taxation_info.price_cents
    assert_equal 0, taxation_info.tax_cents
    assert_nil taxation_info.zip_tax_rate
  end

  test "returns a valid hash even on zero/no/invalid tax calculation" do
    actual_hash = SalesTaxCalculation.zero_tax(100).to_hash

    assert_equal 100, actual_hash[:price_cents]
    assert_equal 0, actual_hash[:tax_cents]
    assert_equal false, actual_hash[:has_vat_id_input]
  end

  test "serializes a valid tax calculation" do
    zip_tax_rate = ZipTaxRate.new(country: "US", is_seller_responsible: false)
    actual_hash = SalesTaxCalculation.new(price_cents: 100,
                                          tax_cents: 10,
                                          zip_tax_rate:).to_hash

    assert_equal 100, actual_hash[:price_cents]
    assert_equal 10, actual_hash[:tax_cents]
    assert_equal false, actual_hash[:has_vat_id_input]
  end

  test "serializes a valid tax calculation for an EU country" do
    zip_tax_rate = ZipTaxRate.new(country: "IT", is_seller_responsible: false)
    actual_hash = SalesTaxCalculation.new(price_cents: 100,
                                          tax_cents: 10,
                                          zip_tax_rate:).to_hash

    assert_equal 100, actual_hash[:price_cents]
    assert_equal 10, actual_hash[:tax_cents]
    assert_equal true, actual_hash[:has_vat_id_input]
  end

  test "serializes a valid tax calculation for Australia" do
    zip_tax_rate = ZipTaxRate.new(country: "AU", is_seller_responsible: false)
    actual_hash = SalesTaxCalculation.new(price_cents: 100,
                                          tax_cents: 10,
                                          zip_tax_rate:).to_hash

    assert_equal 100, actual_hash[:price_cents]
    assert_equal 10, actual_hash[:tax_cents]
    assert_equal true, actual_hash[:has_vat_id_input]
  end

  test "serializes a valid tax calculation for Singapore" do
    zip_tax_rate = ZipTaxRate.new(country: "SG", is_seller_responsible: false)
    actual_hash = SalesTaxCalculation.new(price_cents: 100,
                                          tax_cents: 8,
                                          zip_tax_rate:).to_hash

    assert_equal 100, actual_hash[:price_cents]
    assert_equal 8, actual_hash[:tax_cents]
    assert_equal true, actual_hash[:has_vat_id_input]
  end

  test "serializes a valid tax calculation for Canada province Quebec" do
    actual_hash = SalesTaxCalculation.new(price_cents: 100,
                                          tax_cents: 8,
                                          zip_tax_rate: nil,
                                          is_quebec: true).to_hash

    assert_equal 100, actual_hash[:price_cents]
    assert_equal 8, actual_hash[:tax_cents]
    assert_equal true, actual_hash[:has_vat_id_input]
  end
end
