# frozen_string_literal: true

require "test_helper"

class CartProductTest < ActiveSupport::TestCase
  def build_cart_product(**attrs)
    CartProduct.new(
      cart: carts(:named_seller_cart),
      product: links(:named_seller_product),
      price: 100,
      quantity: 1,
      referrer: "direct",
      **attrs
    )
  end

  test "assigns default url parameters after initialization" do
    assert_equal({}, build_cart_product.url_parameters)
  end

  test "assigns accepted offer details after initialization" do
    assert_equal({}, build_cart_product.accepted_offer_details)
  end

  test "marks the cart product as valid when url parameters are empty" do
    assert_predicate build_cart_product(url_parameters: {}), :valid?
  end

  test "marks the cart product as invalid when url parameters is not a hash" do
    cart_product = build_cart_product(url_parameters: [])
    assert_predicate cart_product, :invalid?
    assert_includes cart_product.errors.full_messages.join,
                    "The property '#/' of type array did not match the following type: object"
  end

  test "marks the cart product as invalid when url parameters contain invalid keys" do
    cart_product = build_cart_product(url_parameters: { "hello" => 123 })
    assert_predicate cart_product, :invalid?
    assert_includes cart_product.errors.full_messages.join,
                    "The property '#/hello' of type integer did not match the following type: string in schema"
  end

  test "marks the cart product as valid when accepted offer details is empty" do
    assert_predicate build_cart_product(accepted_offer_details: {}), :valid?
  end

  test "marks the cart product as invalid when accepted offer details is not a hash" do
    cart_product = build_cart_product(accepted_offer_details: [])
    assert_predicate cart_product, :invalid?
    assert_includes cart_product.errors.full_messages.join,
                    "The property '#/' of type array did not match the following type: object"
  end

  test "marks the cart product as invalid when accepted offer details contains invalid keys" do
    cart_product = build_cart_product(accepted_offer_details: { "hello" => 123 })
    assert_predicate cart_product, :invalid?
    assert_includes cart_product.errors.full_messages.join,
                    "The property '#/' contains additional properties [\"hello\"] outside of the schema when none are allowed in schema"
  end

  test "allows original_variant_id to be nil" do
    assert_predicate build_cart_product(accepted_offer_details: { original_product_id: "123", original_variant_id: nil }), :valid?
    assert_predicate build_cart_product(accepted_offer_details: { original_product_id: "123", original_variant_id: "456" }), :valid?
  end
end
