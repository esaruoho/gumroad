# frozen_string_literal: true

require "test_helper"

class UtmLinkSaleAttributionJobTest < ActiveSupport::TestCase
  setup do
    @product = links(:named_seller_product)
  end

  test "no-op when the order has no successful purchases" do
    order = Order.new
    order.save!(validate: false)
    assert_nothing_raised do
      UtmLinkSaleAttributionJob.new.perform(order.id, "browser-guid-abc")
    end
  end

  test "no-op when there are no visits for the given browser_guid" do
    order = Order.new
    order.save!(validate: false)
    purchase = Purchase.new(seller: @product.user, link: @product, order: order,
                             email: "buyer@example.com", price_cents: 100,
                             total_transaction_cents: 100, fee_cents: 0,
                             purchase_state: "successful")
    purchase.save!(validate: false)
    assert_nothing_raised do
      UtmLinkSaleAttributionJob.new.perform(order.id, "no-visits-here")
    end
    assert_equal 0, UtmLinkDrivenSale.where(purchase_id: purchase.id).count
  end
end
