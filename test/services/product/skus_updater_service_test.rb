# frozen_string_literal: true

require "test_helper"

class Product::SkusUpdaterServiceTest < ActiveSupport::TestCase
  setup do
    @product = links(:skus_updater_physical_product)
    @category1 = VariantCategory.create!(title: "Size", link: @product)
    @variant1 = Variant.create!(variant_category: @category1, name: "Small")
    @category2 = VariantCategory.create!(title: "Color", link: @product)
    @variant2 = Variant.create!(variant_category: @category2, name: "Red")
  end

  def service
    Product::SkusUpdaterService.new(product: @product)
  end

  test "creates the proper skus for one variant per category" do
    service.perform

    assert_equal 2, Sku.count
    assert_equal 1, Sku.not_is_default_sku.count
    last_sku = Sku.not_is_default_sku.last
    assert_equal "Small - Red", last_sku.name
    assert_equal [@variant1, @variant2], last_sku.variants
    assert_equal @product, last_sku.link
  end

  test "creates the proper skus for two variants per category" do
    variant1_1 = Variant.create!(variant_category: @category1, name: "Large")
    variant2_2 = Variant.create!(variant_category: @category2, name: "Blue")
    service.perform

    assert_equal 5, Sku.count
    assert_equal 4, Sku.not_is_default_sku.count
    skus = Sku.not_is_default_sku
    skus.each { |s| assert_equal @product, s.link }
    assert_equal "Small - Red", skus[0].name
    assert_equal [@variant1, @variant2].sort, skus[0].variants.sort
    assert_equal "Small - Blue", skus[1].name
    assert_equal [@variant1, variant2_2].sort, skus[1].variants.sort
    assert_equal "Large - Red", skus[2].name
    assert_equal [variant1_1, @variant2].sort, skus[2].variants.sort
    assert_equal "Large - Blue", skus[3].name
    assert_equal [variant1_1, variant2_2].sort, skus[3].variants.sort
  end

  test "renames the existing sku if the variant name has changed" do
    service.perform
    sku = Sku.last

    @variant1.update!(name: "S")
    service.perform

    assert_equal 2, Sku.count
    assert_equal 1, Sku.not_is_default_sku.count
    last_sku = Sku.not_is_default_sku.last
    assert_equal "S - Red", last_sku.name
    assert_equal [@variant1, @variant2], last_sku.variants
    assert_equal sku.id, last_sku.id
  end

  test "removes the old skus and creates new ones if a new category has been added" do
    service.perform
    old_sku = Sku.last

    new_category = VariantCategory.create!(title: "Pattern", link: @product)
    Variant.create!(variant_category: new_category, name: "Plaid")
    service.perform

    assert_equal 3, Sku.count
    assert_equal 2, Sku.not_is_default_sku.count
    assert_equal "Small - Red - Plaid", Sku.not_is_default_sku.last.name
    assert old_sku.reload.deleted_at.present?
  end

  test "deletes the skus if there are no variant categories left" do
    service.perform

    @category1.mark_deleted
    @category2.mark_deleted

    service.perform

    assert_equal 2, Sku.count
    assert_equal 1, Sku.not_is_default_sku.count
    assert Sku.not_is_default_sku.last.deleted_at.present?
  end

  test "does not delete the default sku" do
    service.perform

    @category1.mark_deleted
    @category2.mark_deleted

    service.perform

    assert_equal 1, Sku.alive.count
    assert_equal 1, Sku.alive.is_default_sku.count
    assert_equal 0, Sku.alive.not_is_default_sku.count
  end

  test "sets the price and quantity properly on existing skus" do
    variant1_1 = Variant.create!(variant_category: @category1, name: "Large")
    variant2_2 = Variant.create!(variant_category: @category2, name: "Blue")
    service.perform

    skus = Sku.not_is_default_sku
    assert_equal 4, skus.count

    skus_params = skus.each_with_index.map do |sku, i|
      {
        price_difference: ((i + 1) * 2 - 1).to_s,
        max_purchase_count: ((i + 1) * 2).to_s,
        id: sku.external_id,
      }
    end
    Product::SkusUpdaterService.new(product: @product, skus_params:).perform

    skus = Sku.not_is_default_sku
    assert_equal 100, skus[0].price_difference_cents
    assert_equal 2,   skus[0].max_purchase_count
    assert_equal 300, skus[1].price_difference_cents
    assert_equal 4,   skus[1].max_purchase_count
    assert_equal 500, skus[2].price_difference_cents
    assert_equal 6,   skus[2].max_purchase_count
    assert_equal 700, skus[3].price_difference_cents
    assert_equal 8,   skus[3].max_purchase_count
  end

  test "raises an error for invalid SKU id in params" do
    service.perform

    skus = Sku.not_is_default_sku
    skus_params = [
      { price_difference: "1", max_purchase_count: "2", id: skus[0].external_id },
      { price_difference: "3", max_purchase_count: "4", id: "not_a_valid_sku" },
    ]

    assert_raises(Link::LinkInvalid) do
      Product::SkusUpdaterService.new(product: @product, skus_params:).perform
    end
  end
end
