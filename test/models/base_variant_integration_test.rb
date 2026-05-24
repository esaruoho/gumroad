require "test_helper"

class BaseVariantIntegrationTest < ActiveSupport::TestCase
  setup do
    @integration = integrations(:circle_integration_one)
    # Use a fresh, isolated variant so fixture-preloaded BVIs don't pollute counts.
    category = variant_categories(:integrations_test_versions_category)
    @variant = Variant.create!(variant_category: category, name: "bvi-test-v", price_difference_cents: 0)
  end

  test "raises error if base_variant_id is not present" do
    bvi = BaseVariantIntegration.new(integration_id: @integration.id)
    assert_equal false, bvi.valid?
    assert_includes bvi.errors.full_messages, "Base variant can't be blank"
  end

  test "raises error if integration_id is not present" do
    bvi = BaseVariantIntegration.new(base_variant_id: @variant.id)
    assert_equal false, bvi.valid?
    assert_includes bvi.errors.full_messages, "Integration can't be blank"
  end

  test "raises error if (base_variant_id, integration_id) is not unique" do
    BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: @variant.id)
    duplicate = BaseVariantIntegration.new(integration_id: @integration.id, base_variant_id: @variant.id)
    assert_equal false, duplicate.valid?
    assert_includes duplicate.errors.full_messages, "Integration has already been taken"
  end

  test "raises error if different variants linked to the same integration are not from the same product" do
    BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: @variant.id)
    other_category = VariantCategory.create!(link: links(:basic_user_product), title: "Size")
    other_variant = Variant.create!(variant_category: other_category, name: "alt", price_difference_cents: 0)
    bvi_2 = BaseVariantIntegration.new(integration_id: @integration.id, base_variant_id: other_variant.id)
    assert_equal false, bvi_2.valid?
    assert_includes bvi_2.errors.full_messages, "Integration has already been taken by a variant from a different product."
  end

  test "is successful if different variants of the same product have the same integration" do
    category = @variant.variant_category
    variant_2 = Variant.create!(variant_category: category, name: "v2", price_difference_cents: 0)
    bvi_1 = BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: @variant.id)
    bvi_2 = BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: variant_2.id)
    assert bvi_1.persisted?
    assert bvi_2.persisted?
  end

  test "is successful if (product_id, integration_id) is not unique but all clashing entries have been deleted" do
    bvi_1 = BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: @variant.id)
    bvi_1.mark_deleted!
    BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: @variant.id)
    assert_equal 2, BaseVariantIntegration.where(base_variant_id: @variant.id, integration_id: @integration.id).count
    assert_equal 1, @variant.active_integrations.count
  end

  test "is successful if same variant has different integrations" do
    other_integration = integrations(:circle_integration_two)
    BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: @variant.id)
    BaseVariantIntegration.create!(integration_id: other_integration.id, base_variant_id: @variant.id)
    assert_equal 2, BaseVariantIntegration.where(base_variant_id: @variant.id).count
  end
end
