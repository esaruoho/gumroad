# frozen_string_literal: true

require "test_helper"

class Order::ResponseHelpersTest < ActiveSupport::TestCase
  class Host
    include Order::ResponseHelpers
    public :error_response
  end

  setup do
    @seller = users(:basic_user)
    @usd_product = links(:basic_user_product)
    @usd_product.update_columns(price_cents: 1500, price_currency_type: Currency::USD)
    @host = Host.new

    # CheckoutPresenter#checkout_product walks heavy product/ES paths.
    # Stub it to a sentinel so we can focus on response shape.
    @orig_cp = CheckoutPresenter.instance_method(:checkout_product)
    CheckoutPresenter.define_method(:checkout_product) do |*_args|
      { stub: true }
    end
  end

  teardown do
    CheckoutPresenter.define_method(:checkout_product, @orig_cp) if @orig_cp
  end

  def build_purchase(**attrs)
    p = Purchase.new(
      link: @usd_product, seller: @seller,
      email: "x@example.com",
      purchase_state: "failed",
      total_transaction_cents: 1500,
      displayed_price_cents: 1500,
      displayed_price_currency_type: "usd",
      ip_country: "United States",
      **attrs
    )
    # Skip validations AND callbacks — product_is_not_blocked callback chokes
    # on nil display_price_cents-derived values; insert directly.
    cols = p.attributes.compact.merge("created_at" => Time.current, "updated_at" => Time.current)
    cols.delete("id")
    id = Purchase.insert(cols).rows.first&.first ||
         Purchase.connection.select_value("SELECT LAST_INSERT_ID()")
    Purchase.find(id)
  end

  test "returns error response for failed purchase" do
    purchase = build_purchase(error_code: "insufficient_funds")
    response = @host.error_response("Payment declined", purchase:)
    assert_equal false, response[:success]
    assert_equal "Payment declined", response[:error_message]
    assert_equal @usd_product.unique_permalink, response[:permalink]
    assert_equal @usd_product.name, response[:name]
    assert_equal "$15", response[:formatted_price]
    assert_equal "insufficient_funds", response[:error_code]
    assert_equal false, response[:is_tax_mismatch]
    assert_equal "United States", response[:ip_country]
  end

  test "uses total_transaction_cents_usd for formatted price" do
    purchase = build_purchase(total_transaction_cents: 2500, error_code: "generic_decline")
    response = @host.error_response("Payment declined", purchase:)
    assert_equal "$25", response[:formatted_price]
  end

  test "sets is_tax_mismatch when error_code is TAX_VALIDATION_FAILED" do
    purchase = build_purchase(error_code: PurchaseErrorCode::TAX_VALIDATION_FAILED)
    response = @host.error_response("Tax validation failed", purchase:)
    assert_equal true, response[:is_tax_mismatch]
    assert_equal PurchaseErrorCode::TAX_VALIDATION_FAILED, response[:error_code]
  end

  test "handles CN card country code (C2 => China)" do
    purchase = build_purchase(card_country: "C2")
    response = @host.error_response("Payment failed", purchase:)
    assert_equal "China", response[:card_country]
  end

  test "handles nil purchase gracefully" do
    response = @host.error_response("Generic error", purchase: nil)
    assert_equal false, response[:success]
    assert_equal "Generic error", response[:error_message]
    assert_nil response[:name]
    assert_equal "$0", response[:formatted_price]
    assert_nil response[:error_code]
    assert_equal false, response[:is_tax_mismatch]
  end
end
