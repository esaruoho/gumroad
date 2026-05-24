# frozen_string_literal: true

require "test_helper"

class DeleteExpiredProductCachedValuesWorkerTest < ActiveSupport::TestCase
  test "deletes expired rows, except the latest (max id) one per product" do
    p1_rows = [
      product_cached_values(:pcv_p1_expired_oldest),
      product_cached_values(:pcv_p1_expired_middle),
      product_cached_values(:pcv_p1_expired_newest),
      product_cached_values(:pcv_p1_not_expired),
    ]
    p2_rows = [
      product_cached_values(:pcv_p2_expired_old),
      product_cached_values(:pcv_p2_expired_new),
    ]
    p3_rows = [
      product_cached_values(:pcv_p3_expired),
      product_cached_values(:pcv_p3_not_expired),
    ]

    # For each product, the worker keeps the row with the max id; all other
    # expired rows are deleted. Non-expired rows that are NOT the max are
    # preserved (the where(.expired) scope excludes them from deletion).
    max_per_product = (p1_rows + p2_rows + p3_rows).group_by(&:product_id)
      .transform_values { |rows| rows.max_by(&:id) }

    expected_deleted = (p1_rows + p2_rows + p3_rows).select do |row|
      row.expired && row.id != max_per_product[row.product_id].id
    end
    expected_kept = (p1_rows + p2_rows + p3_rows) - expected_deleted

    assert_difference -> { ProductCachedValue.count }, -expected_deleted.size do
      DeleteExpiredProductCachedValuesWorker.new.perform
    end

    expected_deleted.each do |row|
      refute ProductCachedValue.exists?(row.id), "expected #{row.id} to be deleted"
    end
    expected_kept.each do |row|
      assert ProductCachedValue.exists?(row.id), "expected #{row.id} to be kept"
    end
  end
end
