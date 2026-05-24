# frozen_string_literal: true

require "test_helper"

class ImportedCustomerTest < ActiveSupport::TestCase
  test "requires an email to create an ImportedCustomer" do
    assert_not ImportedCustomer.new(email: nil).valid?
    assert ImportedCustomer.new(email: "me@maxwell.com").valid?
  end

  test "as_json includes imported customer details" do
    seller = users(:named_seller)
    product = links(:named_seller_product)
    imported_customer = ImportedCustomer.create!(
      importing_user: seller,
      email: "imported@example.com",
      purchase_date: Time.current,
      link: product,
    )

    result = imported_customer.as_json

    assert result["email"].present?
    assert result["created_at"].present?
    assert result[:link_name].present?
    assert result[:product_name].present?
    assert_nil result[:price]
    assert_equal true, result[:is_imported_customer]
    assert result[:purchase_email].present?
    assert result[:id].present?
  end
end
