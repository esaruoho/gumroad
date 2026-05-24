# frozen_string_literal: true

require "test_helper"

class Product::StaffPickedTest < ActiveSupport::TestCase
  setup do
    @product = links(:named_seller_product)
  end

  # #staff_picked?
  test "staff_picked? returns false when there is no staff_picked_product record" do
    assert_equal false, @product.staff_picked?
  end

  test "staff_picked? returns true when staff_picked_product record exists and is not deleted" do
    @product.create_staff_picked_product!
    assert_equal true, @product.staff_picked?
  end

  test "staff_picked? returns false when the staff_picked_product record is deleted" do
    record = @product.create_staff_picked_product!
    record.update_as_deleted!
    assert_equal false, @product.staff_picked?
  end

  # #staff_picked_at
  test "staff_picked_at returns nil when there is no staff_picked_product record" do
    assert_nil @product.staff_picked_at
  end

  test "staff_picked_at returns timestamp when staff_picked_product record exists and is not deleted" do
    record = @product.create_staff_picked_product!
    record.touch
    assert_equal record.updated_at, @product.staff_picked_at
  end

  test "staff_picked_at returns nil when the staff_picked_product record is deleted" do
    record = @product.create_staff_picked_product!
    record.touch
    record.update_as_deleted!
    assert_nil @product.staff_picked_at
  end
end
