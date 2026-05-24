# frozen_string_literal: true

require "test_helper"

class Bundle::UpdateProductsServiceTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @bundle = links(:bundle_update_products_bundle)
    @replacement_product = links(:bundle_update_products_replacement)
    @stale_product = links(:bundle_update_products_stale)
  end

  test "perform ignores deleted bundle products that have become invalid" do
    stale_bundle_product = BundleProduct.create!(bundle: @bundle, product: @stale_product, quantity: 1, position: 0)
    stale_bundle_product.update_column(:deleted_at, Time.current)

    category = VariantCategory.create!(link: @stale_product, title: "Tier")
    2.times { |i| Variant.create!(variant_category: category, name: "v#{i}", price_difference_cents: 0) }

    assert_difference -> { @bundle.bundle_products.alive.count }, 1 do
      Bundle::UpdateProductsService.new(
        bundle: @bundle,
        products: [{ product_id: @replacement_product.external_id, quantity: 1, position: 0 }]
      ).perform
    end

    assert_includes @bundle.reload.bundle_products.alive.pluck(:product_id), @replacement_product.id
  end

  test "perform soft deletes alive bundle products without re-running variant validation" do
    stale_bundle_product = BundleProduct.create!(bundle: @bundle, product: @stale_product, quantity: 1, position: 0)

    category = VariantCategory.create!(link: @stale_product, title: "Tier")
    2.times { |i| Variant.create!(variant_category: category, name: "v#{i}", price_difference_cents: 0) }

    Bundle::UpdateProductsService.new(
      bundle: @bundle,
      products: [{ product_id: @replacement_product.external_id, quantity: 1, position: 0 }]
    ).perform

    assert stale_bundle_product.reload.deleted?
    assert_includes @bundle.reload.bundle_products.alive.pluck(:product_id), @replacement_product.id
  end

  test "perform restores a previously deleted bundle product instead of creating a duplicate" do
    deleted_bundle_product = BundleProduct.create!(bundle: @bundle, product: @replacement_product, quantity: 1, position: 5)
    deleted_bundle_product.update_column(:deleted_at, Time.current)

    assert_no_difference -> { BundleProduct.count } do
      Bundle::UpdateProductsService.new(
        bundle: @bundle,
        products: [{ product_id: @replacement_product.external_id, quantity: 1, position: 0 }]
      ).perform
    end

    assert deleted_bundle_product.reload.alive?
    assert_equal 0, deleted_bundle_product.position
    assert_equal [@replacement_product.id], @bundle.reload.bundle_products.alive.pluck(:product_id)
  end
end
