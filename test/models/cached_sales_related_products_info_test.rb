# frozen_string_literal: true

require "test_helper"

class CachedSalesRelatedProductsInfoTest < ActiveSupport::TestCase
  setup do
    @product = links(:named_seller_product)
  end

  test "validates counts column format" do
    record = CachedSalesRelatedProductsInfo.new(product: @product, counts: { "123" => "bar" })
    assert_not record.valid?
    assert record.errors[:counts].present?

    record = CachedSalesRelatedProductsInfo.new(product: @product, counts: { "foo" => 1 })
    assert_not record.valid?
    assert record.errors[:counts].present?

    record = CachedSalesRelatedProductsInfo.new(product: @product, counts: { "123" => 456 })
    assert record.valid?
  end

  test "#normalized_counts converts keys into integers" do
    record = CachedSalesRelatedProductsInfo.create!(product: @product, counts: { 123 => 456 })
    record.reload
    assert_equal({ "123" => 456 }, record.counts)
    assert_equal({ 123 => 456 }, record.normalized_counts)
  end
end
