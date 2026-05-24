# frozen_string_literal: true

require "test_helper"

class BundleProductPurchaseTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @product = links(:named_seller_product)
    # Reuse existing fixture purchases for the same seller.
    @bundle_purchase = purchases(:audience_purchase)
    @product_purchase = purchases(:auto_invoice_enabled_purchase)
    @other_seller_purchase = purchases(:community_buyer_purchase)
  end

  test "is valid when bundle and product purchases share the same seller and product is not a bundle" do
    bpp = BundleProductPurchase.new(bundle_purchase: @bundle_purchase, product_purchase: @product_purchase)
    assert bpp.valid?, bpp.errors.full_messages.join(", ")
  end

  test "is invalid when bundle and product purchases have different sellers" do
    bpp = BundleProductPurchase.new(bundle_purchase: @bundle_purchase, product_purchase: @other_seller_purchase)
    assert_not bpp.valid?
    assert_equal "Seller must be the same for bundle and product purchases", bpp.errors.full_messages.first
  end

  test "is invalid when product purchase is for a bundle product" do
    # Flip is_bundle bit on the product so product_purchase.link.is_bundle? returns true.
    @product.is_bundle = true
    @product.save!(validate: false)

    bpp = BundleProductPurchase.new(bundle_purchase: @bundle_purchase, product_purchase: @product_purchase)
    assert_not bpp.valid?
    assert_equal "Product purchase cannot be a bundle purchase", bpp.errors.full_messages.first
  end
end
