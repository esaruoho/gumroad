# frozen_string_literal: true

require "test_helper"

class IntegrationsTest < ActiveSupport::TestCase
  fixtures :links, :integrations, :product_integrations, :variant_categories,
           :base_variants, :base_variant_integrations

  test "find_integration_by_name on a product returns the first integration of the given type" do
    product = links(:named_seller_product)
    # `.first` on a has_many returns lowest id, regardless of insertion order.
    expected = product.active_integrations.by_name(Integration::CIRCLE).order(:id).first
    assert_equal expected, product.find_integration_by_name(Integration::CIRCLE)
    assert_kind_of CircleIntegration, product.find_integration_by_name(Integration::CIRCLE)
  end

  test "find_integration_by_name on a base variant returns the first integration of the given type" do
    variant = base_variants(:integrations_test_variant_v1)
    expected = variant.active_integrations.by_name(Integration::CIRCLE).order(:id).first
    assert_equal expected, variant.find_integration_by_name(Integration::CIRCLE)
    assert_kind_of CircleIntegration, variant.find_integration_by_name(Integration::CIRCLE)
  end
end
