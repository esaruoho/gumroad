# frozen_string_literal: true

require "test_helper"

class Product::VariantCategoryUpdaterServiceTest < ActiveSupport::TestCase
  test "ALLOWED_ATTRIBUTES lists the variant fields the service is willing to write" do
    expected = %i[
      name
      description
      price_difference_cents
      max_purchase_count
      position_in_category
      customizable_price
      subscription_price_change_effective_date
      subscription_price_change_message
      duration_in_minutes
      apply_price_changes_to_existing_memberships
      variant_category
      product_files
    ]
    assert_equal expected, Product::VariantCategoryUpdaterService::ALLOWED_ATTRIBUTES
  end

  test "initializer captures product and category_params" do
    product = links(:named_seller_product)
    category_params = { name: "Tier", variants: [] }

    service = Product::VariantCategoryUpdaterService.new(product: product, category_params: category_params)

    assert_equal product, service.product
    assert_equal category_params, service.category_params
    # delegated reader pulls through to the product
    assert_equal product.price_currency_type, service.price_currency_type
  end

  # TODO: full perform behaviour (16 FactoryBot refs) updates tiered membership
  # plans, ties variants to product files, recalculates skus, and runs through
  # subscription price-change effective dates. That requires a tiered_membership
  # + product_files + skus + subscriptions fixture chain not yet on this branch.
  # Original: spec/services/product/variant_category_updater_service_spec.rb
end
