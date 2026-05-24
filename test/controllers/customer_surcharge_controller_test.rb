# frozen_string_literal: true

require "test_helper"

class CustomerSurchargeControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @product = links(:basic_user_product)
    @physical_product = links(:audience_physical_product)
  end

  test "returns 0 if price input is invalid" do
    post :calculate_all, params: { products: [{ permalink: @physical_product.unique_permalink, price: "invalid", quantity: 1 }] }, as: :json
    assert_equal({
      "vat_id_valid" => false,
      "has_vat_id_input" => false,
      "shipping_rate_cents" => 0,
      "tax_cents" => 0,
      "tax_included_cents" => 0,
      "subtotal" => 0,
    }, JSON.parse(@response.body))
  end

  test "returns the correct non-zero tax value when buyer location is EU and no VAT ID is provided" do
    ZipTaxRate.create!(combined_rate: 0.19, country: "DE", state: nil, zip_code: nil, is_seller_responsible: false)
    post :calculate_all, params: { products: [{ permalink: @product.unique_permalink, price: 100, quantity: 1 }], postal_code: 10115, country: "DE" }, as: :json
    body = JSON.parse(@response.body)
    assert_equal 19, body["tax_cents"]
    assert_equal 100, body["subtotal"]
    assert_equal false, body["vat_id_valid"]
    assert_equal true, body["has_vat_id_input"]
  end

  test "returns the correct tax value and an invalid VAT ID status when buyer location is EU and the VAT ID provided is invalid" do
    ZipTaxRate.create!(combined_rate: 0.19, country: "DE", state: nil, zip_code: nil, is_seller_responsible: false)
    post :calculate_all, params: { products: [{ permalink: @product.unique_permalink, price: 100, quantity: 1 }], postal_code: 10115, country: "DE", vat_id: "DE123" }, as: :json
    body = JSON.parse(@response.body)
    assert_equal 19, body["tax_cents"]
    assert_equal false, body["vat_id_valid"]
    assert_equal true, body["has_vat_id_input"]
  end
end
