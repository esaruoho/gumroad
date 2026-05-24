# frozen_string_literal: true

require "test_helper"

class BaseVariantIntegrationTest < ActiveSupport::TestCase
  setup do
    # Use a circle integration NOT already wired to any base_variant in fixtures.
    @integration = integrations(:circle_integration_one)
    # Create a fresh product + variant_category + variant for isolation.
    @product = create_product
    @variant_category = VariantCategory.create!(link: @product, title: "Size")
    @variant = Variant.create!(variant_category: @variant_category, price_difference_cents: 0, name: "small")
  end

  test "raises error if base_variant_id is not present" do
    bvi = BaseVariantIntegration.new(integration_id: @integration.id)
    assert_not bvi.valid?
    assert_includes bvi.errors.full_messages, "Base variant can't be blank"
  end

  test "raises error if integration_id is not present" do
    bvi = BaseVariantIntegration.new(base_variant_id: @variant.id)
    assert_not bvi.valid?
    assert_includes bvi.errors.full_messages, "Integration can't be blank"
  end

  test "raises error if (base_variant_id, integration_id) is not unique" do
    BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: @variant.id)
    dup = BaseVariantIntegration.new(integration_id: @integration.id, base_variant_id: @variant.id)
    assert_not dup.valid?
    assert_includes dup.errors.full_messages, "Integration has already been taken"
  end

  test "raises error if different variants linked to the same integration are not from the same product" do
    BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: @variant.id)
    other_product = create_product
    other_category = VariantCategory.create!(link: other_product, title: "Size")
    other_variant = Variant.create!(variant_category: other_category, price_difference_cents: 0, name: "other")

    bvi = BaseVariantIntegration.new(integration_id: @integration.id, base_variant_id: other_variant.id)
    assert_not bvi.valid?
    assert_includes bvi.errors.full_messages, "Integration has already been taken by a variant from a different product."
  end

  test "is successful if different variants of the same product have the same integration" do
    v2 = Variant.create!(variant_category: @variant_category, price_difference_cents: 0, name: "medium")
    BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: @variant.id)
    BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: v2.id)
    assert_equal 2, BaseVariantIntegration.where(integration_id: @integration.id).count
  end

  test "is successful if clashing entries have been deleted" do
    first = BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: @variant.id)
    first.mark_deleted!
    BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: @variant.id)
    assert_equal 2, BaseVariantIntegration.where(integration_id: @integration.id, base_variant_id: @variant.id).count
    assert_equal 1, @variant.active_integrations.count
  end

  test "is successful if same variant has different integrations" do
    other_integration = CircleIntegration.create!(api_key: "another-key", community_id: "9999", space_group_id: "9999")
    BaseVariantIntegration.create!(integration_id: @integration.id, base_variant_id: @variant.id)
    BaseVariantIntegration.create!(integration_id: other_integration.id, base_variant_id: @variant.id)
    assert_equal 2, BaseVariantIntegration.where(base_variant_id: @variant.id).count
  end

  private
    def create_product
      seller = users(:bvi_test_seller)
      link = Link.new(
        user: seller,
        name: "BVI test product #{SecureRandom.hex(4)}",
        price_cents: 100,
        purchase_type: 0,
        native_type: "digital",
        filetype: "link",
        filegroup: "url"
      )
      link.save!
      link
    end
end
