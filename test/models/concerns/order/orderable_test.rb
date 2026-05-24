# frozen_string_literal: true

require "test_helper"

class OrderableTest < ActiveSupport::TestCase
  setup do
    @product = links(:basic_user_product)
    @physical_product = make_physical_link
  end

  # ---- helpers ----

  def make_physical_link
    seller = users(:another_seller)
    link = Link.new(user: seller, name: "Orderable physical", unique_permalink: "ordph#{SecureRandom.hex(3).tr('0-9','abcdefghij')}",
                    price_cents: 100, native_type: "physical", filetype: "link", filegroup: "url",
                    flags: Link.flag_mapping["flags"][:is_physical], require_shipping: true)
    link.save!(validate: false)
    link
  end

  def build_purchase(link: @product, purchase_state: "successful", flags: 0)
    p = Purchase.new(link: link, seller: link.user, email: "ord-#{SecureRandom.hex(3)}@example.com",
                     purchase_state: purchase_state, total_transaction_cents: link.price_cents,
                     displayed_price_cents: link.price_cents, displayed_price_currency_type: "usd",
                     price_cents: link.price_cents, fee_cents: 0, flags: flags)
    cols = p.attributes.compact.merge("created_at" => Time.current, "updated_at" => Time.current)
    cols.delete("id")
    id = Purchase.insert(cols).rows.first&.first ||
         Purchase.connection.select_value("SELECT LAST_INSERT_ID()")
    Purchase.find(id)
  end

  # ----- For Purchase -----

  # #require_shipping?

  test "Purchase#require_shipping? returns false when the product is not physical" do
    purchase = build_purchase
    assert_equal false, purchase.require_shipping?
  end

  test "Purchase#require_shipping? returns true when product is physical" do
    purchase = build_purchase(link: @physical_product)
    assert_equal true, purchase.require_shipping?
  end

  # #receipt_for_gift_receiver?

  test "Purchase#receipt_for_gift_receiver? returns false when the purchase is not for a gift receiver" do
    purchase = build_purchase
    assert_equal false, purchase.receipt_for_gift_receiver?
  end

  test "Purchase#receipt_for_gift_receiver? returns true when the purchase is for a gift receiver" do
    bit = Purchase.flag_mapping["flags"][:is_gift_receiver_purchase]
    purchase = build_purchase(flags: bit)
    assert_equal true, purchase.receipt_for_gift_receiver?
  end

  # #receipt_for_gift_sender?

  test "Purchase#receipt_for_gift_sender? returns false when the purchase is not for a gift sender" do
    purchase = build_purchase
    assert_equal false, purchase.receipt_for_gift_sender?
  end

  test "Purchase#receipt_for_gift_sender? returns true when the purchase is for a gift sender" do
    bit = Purchase.flag_mapping["flags"][:is_gift_sender_purchase]
    purchase = build_purchase(flags: bit)
    assert_equal true, purchase.receipt_for_gift_sender?
  end

  # #test?

  test "Purchase#test? returns false when the purchase is not a test purchase" do
    purchase = build_purchase
    assert_equal false, purchase.test?
  end

  test "Purchase#test? returns true when the purchase is a test purchase (buyer == seller)" do
    # is_test_purchase? returns true when link.user == purchaser.
    purchase = build_purchase
    purchase.update_columns(purchaser_id: @product.user_id)
    purchase.reload
    assert_equal true, purchase.test?
  end

  # #seller_receipt_enabled?

  test "Purchase#seller_receipt_enabled? returns false" do
    purchase = build_purchase
    assert_equal false, purchase.seller_receipt_enabled?
  end

  # ----- For Order — delegates via super -----

  test "Order#require_shipping? calls super" do
    order = Order.new
    order.define_singleton_method(:require_shipping?) { "super" }
    assert_equal "super", order.require_shipping?
  end

  test "Order#receipt_for_gift_receiver? calls super" do
    order = Order.new
    order.define_singleton_method(:receipt_for_gift_receiver?) { "super" }
    assert_equal "super", order.receipt_for_gift_receiver?
  end

  test "Order#receipt_for_gift_sender? calls super" do
    order = Order.new
    order.define_singleton_method(:receipt_for_gift_sender?) { "super" }
    assert_equal "super", order.receipt_for_gift_sender?
  end

  test "Order#test? calls super" do
    order = Order.new
    order.define_singleton_method(:test?) { "super" }
    assert_equal "super", order.test?
  end

  test "Order#seller_receipt_enabled? calls super" do
    order = Order.new
    order.define_singleton_method(:seller_receipt_enabled?) { "super" }
    assert_equal "super", order.seller_receipt_enabled?
  end

  # ----- #uses_charge_receipt? -----

  test "Order#uses_charge_receipt? returns true" do
    order = Order.create!
    assert_equal true, order.uses_charge_receipt?
  end

  test "Purchase#uses_charge_receipt? returns false when there is no charge associated" do
    purchase = build_purchase
    assert_equal false, purchase.uses_charge_receipt?
  end

  test "Purchase#uses_charge_receipt? returns false when there is an order associated without a charge" do
    purchase = build_purchase
    order = Order.create!
    order.purchases << purchase
    assert_nil purchase.reload.charge
    assert_equal false, purchase.uses_charge_receipt?
  end

  test "Purchase#uses_charge_receipt? returns true when there is a charge associated" do
    purchase = build_purchase
    order = Order.create!
    charge = Charge.create!(order: order, seller: @product.user)
    charge.purchases << purchase
    assert_equal true, purchase.reload.uses_charge_receipt?
  end
end
