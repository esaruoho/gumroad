# frozen_string_literal: true

require "test_helper"

class StaffPickedProductTest < ActiveSupport::TestCase
  test "validates presence of product" do
    staff_picked_product = StaffPickedProduct.new
    assert_not staff_picked_product.valid?
    assert_equal :blank, staff_picked_product.errors.details[:product].first[:error]
  end

  test "cannot create record with same product" do
    product = links(:named_seller_product)
    StaffPickedProduct.create!(product: product)

    new_record = StaffPickedProduct.new(product: product)
    assert_not new_record.valid?
    assert_equal :taken, new_record.errors.details[:product].first[:error]
  end
end
