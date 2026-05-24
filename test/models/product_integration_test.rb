# frozen_string_literal: true

require "test_helper"

class ProductIntegrationTest < ActiveSupport::TestCase
  setup do
    # Use an integration / product pair NOT already wired together via fixtures.
    # `circle_integration_for_variant_one` is wired to variants in some fixtures
    # but not directly to a product → safe to use here.
    @integration = integrations(:circle_integration_for_variant_one)
    @product = links(:preorder_test_product)
    # Ensure isolation from any seed product_integrations rows.
    ProductIntegration.where(product_id: @product.id, integration_id: @integration.id).delete_all
  end

  test "raises error if product_id is not present" do
    product_integration = ProductIntegration.new(integration_id: @integration.id)
    assert_not product_integration.valid?
    assert_includes product_integration.errors.full_messages, "Product can't be blank"
  end

  test "raises error if integration_id is not present" do
    product_integration = ProductIntegration.new(product_id: @product.id)
    assert_not product_integration.valid?
    assert_includes product_integration.errors.full_messages, "Integration can't be blank"
  end

  test "raises error if (product_id, integration_id) is not unique" do
    ProductIntegration.create!(integration_id: @integration.id, product_id: @product.id)
    product_integration_2 = ProductIntegration.new(integration_id: @integration.id, product_id: @product.id)
    assert_not product_integration_2.valid?
    assert_includes product_integration_2.errors.full_messages, "Integration has already been taken"
  end

  test "is successful if (product_id, integration_id) is not unique but all clashing entries have been deleted" do
    product_integration_1 = ProductIntegration.create!(integration_id: @integration.id, product_id: @product.id)
    product_integration_1.mark_deleted!
    ProductIntegration.create!(integration_id: @integration.id, product_id: @product.id)
    assert_equal 2, ProductIntegration.where(product_id: @product.id, integration_id: @integration.id).count
    assert_equal 1, @product.active_integrations.count
  end

  test "is successful if same product has different integrations" do
    ProductIntegration.create!(integration_id: @integration.id, product_id: @product.id)
    other_integration = integrations(:circle_integration_for_variant_two)
    ProductIntegration.where(product_id: @product.id, integration_id: other_integration.id).delete_all
    ProductIntegration.create!(integration_id: other_integration.id, product_id: @product.id)
    assert_equal 2, ProductIntegration.where(product_id: @product.id).count
  end
end
