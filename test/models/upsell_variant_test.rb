require "test_helper"

class UpsellVariantTest < ActiveSupport::TestCase
  test "adds an error when the variants don't belong to the upsell's offered product" do
    other_product_1 = Link.create!(user: users(:another_seller), name: "Other product 1", price_cents: 100)
    other_product_2 = Link.create!(user: users(:basic_user), name: "Other product 2", price_cents: 100)
    selected_category = VariantCategory.create!(link: other_product_1, title: "Size")
    offered_category = VariantCategory.create!(link: other_product_2, title: "Size")
    selected_variant = Variant.create!(variant_category: selected_category, name: "A", price_difference_cents: 0)
    offered_variant = Variant.create!(variant_category: offered_category, name: "B", price_difference_cents: 0)

    upsell_variant = UpsellVariant.new(
      upsell: upsells(:named_seller_upsell),
      selected_variant: selected_variant,
      offered_variant: offered_variant,
    )

    assert_equal false, upsell_variant.valid?
    assert_equal "The selected variant and the offered variant must belong to the upsell's offered product.",
                 upsell_variant.errors.full_messages.first
  end

  test "doesn't add an error when the variants belong to the upsell's offered product" do
    upsell = upsells(:named_seller_upsell)
    product = upsell.product
    selected_category = VariantCategory.create!(link: product, title: "Size A")
    offered_category = VariantCategory.create!(link: product, title: "Size B")
    selected_variant = Variant.create!(variant_category: selected_category, name: "A", price_difference_cents: 0)
    offered_variant = Variant.create!(variant_category: offered_category, name: "B", price_difference_cents: 0)

    upsell_variant = UpsellVariant.new(
      upsell: upsell,
      selected_variant: selected_variant,
      offered_variant: offered_variant,
    )

    assert_equal true, upsell_variant.valid?
  end
end
