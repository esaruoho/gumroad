# frozen_string_literal: true

require "test_helper"

class SellerProfileProductsSectionTest < ActiveSupport::TestCase
  test "validates json_data with the correct schema" do
    section = SellerProfileProductsSection.new(
      seller: users(:named_seller),
      default_product_sort: "page_layout",
      shown_products: [links(:named_seller_product).id],
      show_filters: false,
      add_new_products: true,
    )
    section.json_data["garbage"] = "should not be here"

    section.validate

    assert_equal "The property '#/' contains additional properties [\"garbage\"] outside of the schema when none are allowed",
                 section.errors.full_messages.to_sentence
  end

  test "#product_names returns the names of the products in the section" do
    seller = users(:named_seller)
    product_a = links(:named_seller_product)
    product_b = links(:named_seller_archived_product)

    section = SellerProfileProductsSection.create!(
      seller: seller,
      default_product_sort: "page_layout",
      shown_products: [product_a.id, product_b.id],
      show_filters: false,
      add_new_products: true,
    )

    assert_equal [product_a.name, product_b.name].sort, section.product_names.sort
  end
end
