# frozen_string_literal: true

require "test_helper"

class UpdateLargeSellersSalesCountJobTest < ActiveSupport::TestCase
  setup do
    @ls1 = large_sellers(:large_seller_one)   # basic_user
    @ls2 = large_sellers(:large_seller_two)   # named_seller
    @ls1.update_columns(sales_count: 1000)
    @ls2.update_columns(sales_count: 2000)
  end

  test "updates sales_count when count has changed" do
    actual_count_basic = users(:basic_user).sales.count
    actual_count_named = users(:named_seller).sales.count

    UpdateLargeSellersSalesCountJob.new.perform

    assert_equal actual_count_basic, @ls1.reload.sales_count
    assert_equal actual_count_named, @ls2.reload.sales_count
  end

  test "does not update when count is unchanged" do
    @ls1.update_columns(sales_count: users(:basic_user).sales.count)
    updated_at_before = @ls1.reload.updated_at
    travel 2.seconds do
      UpdateLargeSellersSalesCountJob.new.perform
    end
    assert_equal updated_at_before.to_i, @ls1.reload.updated_at.to_i
  end

  test "skips large sellers without users" do
    @ls1.update_columns(user_id: nil)
    assert_nothing_raised do
      UpdateLargeSellersSalesCountJob.new.perform
    end
    assert_equal users(:named_seller).sales.count, @ls2.reload.sales_count
  end
end
