# frozen_string_literal: true

require "test_helper"

class SalesRelatedProductsInfoTest < ActiveSupport::TestCase
  setup do
    # Use 6 link fixtures with stable, low-collision ids. Wipe any pre-existing
    # SRPI/cache rows so the seeded data we assert on isn't contaminated by
    # other fixtures (recommended_sample_to_* etc.).
    SalesRelatedProductsInfo.delete_all
    CachedSalesRelatedProductsInfo.delete_all
    @products = [
      links(:discover_service_product_one),
      links(:discover_service_product_two),
      links(:discover_service_product_three),
      links(:recommended_product_one),
      links(:recommended_product_two),
      links(:recommended_product_three),
    ]
  end

  def make_srpi(small_idx, large_idx, sales_count:)
    a, b = @products[small_idx].id, @products[large_idx].id
    smaller, larger = [a, b].minmax
    SalesRelatedProductsInfo.create!(smaller_product_id: smaller, larger_product_id: larger, sales_count:)
  end

  def rebuild_srpis_cache
    CachedSalesRelatedProductsInfo.delete_all
    Link.ids.each { UpdateCachedSalesRelatedProductsInfosJob.new.perform(_1) }
  end

  # --- .find_or_create_info ---

  test "find_or_create_info returns existing info regardless of arg order" do
    srpi = make_srpi(0, 1, sales_count: 1)
    assert_equal srpi, SalesRelatedProductsInfo.find_or_create_info(srpi.smaller_product_id, srpi.larger_product_id)
    assert_equal srpi, SalesRelatedProductsInfo.find_or_create_info(srpi.larger_product_id, srpi.smaller_product_id)
  end

  test "find_or_create_info creates new row when missing" do
    p1, p2 = @products[0], @products[1]
    assert_difference -> { SalesRelatedProductsInfo.count }, 1 do
      SalesRelatedProductsInfo.find_or_create_info(p1.id, p2.id)
    end
    smaller, larger = [p1.id, p2.id].minmax
    row = SalesRelatedProductsInfo.last
    assert_equal smaller, row.smaller_product_id
    assert_equal larger, row.larger_product_id
  end

  # --- .update_sales_counts ---

  test "update_sales_counts upserts and increments/decrements sales counts" do
    # Use 4 sorted products by id for deterministic smaller/larger pairing.
    products = @products.first(4).sort_by(&:id)
    make_srpi_for_pair = ->(a, b, count) do
      smaller, larger = [a.id, b.id].minmax
      SalesRelatedProductsInfo.create!(smaller_product_id: smaller, larger_product_id: larger, sales_count: count)
    end

    make_srpi_for_pair.call(products[1], products[2], 5)

    SalesRelatedProductsInfo.update_sales_counts(
      product_id: products[1].id,
      related_product_ids: products.map(&:id) - [products[1].id],
      increment: true,
    )

    find_by_pair = ->(a, b) do
      smaller, larger = [a.id, b.id].minmax
      SalesRelatedProductsInfo.find_by(smaller_product_id: smaller, larger_product_id: larger)
    end

    assert_equal 1, find_by_pair.call(products[0], products[1]).sales_count
    assert_equal 1, find_by_pair.call(products[1], products[3]).sales_count
    assert_equal 6, find_by_pair.call(products[1], products[2]).sales_count

    products_ext = products + [@products[4]]
    SalesRelatedProductsInfo.update_sales_counts(
      product_id: products[1].id,
      related_product_ids: products_ext.map(&:id) - [products[1].id],
      increment: false,
    )

    assert_equal 0, find_by_pair.call(products[0], products[1]).sales_count
    assert_equal 5, find_by_pair.call(products[1], products[2]).sales_count
    assert_equal 0, find_by_pair.call(products[1], products[3]).sales_count
    assert_equal 0, find_by_pair.call(products[1], products_ext[4]).sales_count
  end

  # --- .related_products ---

  test "related_products returns related products sorted by sales count desc" do
    products = @products
    make_srpi(0, 3, sales_count: 7)
    make_srpi(1, 3, sales_count: 3)
    make_srpi(1, 2, sales_count: 7)
    make_srpi(2, 5, sales_count: 9)
    make_srpi(2, 3, sales_count: 5)
    make_srpi(2, 4, sales_count: 6)
    rebuild_srpis_cache

    # products[1] is first (3+7=10), products[5] (9), products[0] (7), products[4] (6)
    assert_equal [products[1], products[5], products[0], products[4]],
                 SalesRelatedProductsInfo.related_products([products[2].id, products[3].id])

    assert_equal [products[5], products[1], products[4]],
                 SalesRelatedProductsInfo.related_products([products[2].id], limit: 3)

    assert_equal [], SalesRelatedProductsInfo.related_products([0])
    assert_equal [], SalesRelatedProductsInfo.related_products([])
  end

  test "related_products validates arguments" do
    err = assert_raises(ArgumentError) { SalesRelatedProductsInfo.related_products([1, "bad", 2]) }
    assert_match(/must be an array of integers/, err.message)

    err = assert_raises(ArgumentError) { SalesRelatedProductsInfo.related_products([1], limit: "bad") }
    assert_match(/must an integer/, err.message)
  end

  # --- .related_product_ids_and_sales_counts ---

  test "related_product_ids_and_sales_counts validates the arguments" do
    err = assert_raises(ArgumentError) { SalesRelatedProductsInfo.related_product_ids_and_sales_counts("bad") }
    assert_equal "product_id must be an integer", err.message

    err = assert_raises(ArgumentError) { SalesRelatedProductsInfo.related_product_ids_and_sales_counts(1, limit: "bad") }
    assert_equal "limit must be an integer", err.message
  end

  test "related_product_ids_and_sales_counts returns a hash of related products and sales counts" do
    data = [
      [1, 2, 12], [1, 3, 13], [1, 4, 100], [1, 5, 15],
      [2, 4, 24], [3, 4, 34], [4, 5, 45], [4, 6, 46], [4, 7, 47],
    ]
    data.each do |s, l, c|
      SalesRelatedProductsInfo.insert!({ smaller_product_id: s, larger_product_id: l, sales_count: c })
    end

    result = SalesRelatedProductsInfo.related_product_ids_and_sales_counts(4, limit: 3)
    assert_equal({ 1 => 100, 7 => 47, 6 => 46 }, result)
  end

  # --- validation: smaller_product_id < larger_product_id ---

  test "invalid when smaller_product_id is greater than larger_product_id" do
    p1, p2 = @products[0], @products[1]
    smaller, larger = [p1.id, p2.id].minmax
    srpi = SalesRelatedProductsInfo.new(smaller_product_id: larger, larger_product_id: smaller)
    refute srpi.valid?
  end

  test "invalid when smaller_product_id equals larger_product_id" do
    p = @products[0]
    srpi = SalesRelatedProductsInfo.new(smaller_product_id: p.id, larger_product_id: p.id)
    refute srpi.valid?
  end

  test "valid when smaller_product_id is less than larger_product_id" do
    p1, p2 = @products[0], @products[1]
    smaller, larger = [p1.id, p2.id].minmax
    srpi = SalesRelatedProductsInfo.new(smaller_product_id: smaller, larger_product_id: larger)
    assert srpi.valid?
  end

  # --- .for_product_id scope ---

  test "for_product_id returns matching records for a product id" do
    record = make_srpi(0, 1, sales_count: 2)
    make_srpi(2, 3, sales_count: 2)
    assert_equal [record], SalesRelatedProductsInfo.for_product_id(record.smaller_product_id).to_a
    assert_equal [record], SalesRelatedProductsInfo.for_product_id(record.larger_product_id).to_a
  end
end
