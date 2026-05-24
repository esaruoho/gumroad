# frozen_string_literal: true

require "test_helper"

class Workflow::AbandonedCartProductsTest < ActiveSupport::TestCase
  # NOTE: we intentionally do not `include Rails.application.routes.url_helpers`
  # here — the concern itself includes it on Workflow, and including it on a
  # TestCase exposes every route helper as a `test_*` method.

  setup do
    @seller = users(:abandoned_cart_seller)
    @product1 = links(:abandoned_cart_product_1)
    @product2 = links(:abandoned_cart_product_2)
    @variant1 = base_variants(:abandoned_cart_product_2_variant_1)
    @variant2 = base_variants(:abandoned_cart_product_2_variant_2)
  end

  def build_workflow(workflow_type:, **attrs)
    Workflow.create!(
      seller: @seller,
      name: "wf #{workflow_type}",
      workflow_type: workflow_type,
      **attrs
    )
  end

  def normalize(products)
    products.map do |p|
      p2 = p.dup
      p2[:variants] = p2[:variants].sort_by { _1[:external_id] }
      p2
    end.sort_by { _1[:unique_permalink] }
  end

  def product_json(product, variants:)
    {
      unique_permalink: product.unique_permalink,
      external_id: product.external_id,
      name: product.name,
      thumbnail_url: product.for_email_thumbnail_url,
      url: product.long_url,
      variants: variants,
      seller: {
        name: @seller.display_name,
        avatar_url: @seller.avatar_url,
        profile_url: @seller.profile_url,
      }
    }
  end

  test "returns empty array when it is not an abandoned cart workflow" do
    workflow = build_workflow(workflow_type: Workflow::SELLER_TYPE)
    assert_empty workflow.abandoned_cart_products
    assert_empty workflow.abandoned_cart_products(only_product_and_variant_ids: true)
  end

  test "returns all products and variants that are not archived when filters are not provided" do
    workflow = build_workflow(workflow_type: Workflow::ABANDONED_CART_TYPE)

    expected = [
      product_json(@product1, variants: []),
      product_json(@product2, variants: [
        { external_id: @variant1.external_id, name: @variant1.name },
        { external_id: @variant2.external_id, name: @variant2.name }
      ])
    ]

    assert_equal normalize(expected), normalize(workflow.abandoned_cart_products)
    assert_equal [[@product1.id, []], [@product2.id, [@variant1.id, @variant2.id].sort]].sort,
                 workflow.abandoned_cart_products(only_product_and_variant_ids: true).map { |id, vs| [id, vs.sort] }.sort
  end

  test "includes the product if at least one of its variants is selected" do
    workflow = build_workflow(workflow_type: Workflow::ABANDONED_CART_TYPE)
    workflow.bought_variants = [@variant1.external_id]
    workflow.save!

    expected = [product_json(@product2, variants: [{ external_id: @variant1.external_id, name: @variant1.name }])]
    assert_equal expected, workflow.abandoned_cart_products
    assert_equal [[@product2.id, [@variant1.id]]], workflow.abandoned_cart_products(only_product_and_variant_ids: true)
  end

  test "includes the product along with all its variants if it is selected and one of its variants is selected" do
    workflow = build_workflow(workflow_type: Workflow::ABANDONED_CART_TYPE)
    workflow.bought_products = [@product2.unique_permalink]
    workflow.bought_variants = [@variant2.external_id]
    workflow.save!

    expected = [product_json(@product2, variants: [
      { external_id: @variant1.external_id, name: @variant1.name },
      { external_id: @variant2.external_id, name: @variant2.name }
    ])]
    assert_equal normalize(expected), normalize(workflow.abandoned_cart_products)
    assert_equal [[@product2.id, [@variant1.id, @variant2.id].sort]],
                 workflow.abandoned_cart_products(only_product_and_variant_ids: true).map { |id, vs| [id, vs.sort] }
  end

  test "does not include the product if 'not_bought_products' filter includes it even though one of its variants is selected" do
    workflow = build_workflow(workflow_type: Workflow::ABANDONED_CART_TYPE)
    workflow.not_bought_products = [@product2.unique_permalink]
    workflow.bought_variants = [@variant1.external_id]
    workflow.save!

    assert_empty workflow.abandoned_cart_products
    assert_empty workflow.abandoned_cart_products(only_product_and_variant_ids: true)
  end

  test "does not include a product's variant if 'not_bought_variants' filter includes it" do
    workflow = build_workflow(workflow_type: Workflow::ABANDONED_CART_TYPE)
    workflow.bought_products = [@product2.unique_permalink]
    workflow.not_bought_variants = [@variant2.external_id]
    workflow.save!

    expected = [product_json(@product2, variants: [{ external_id: @variant1.external_id, name: @variant1.name }])]
    assert_equal expected, workflow.abandoned_cart_products
    assert_equal [[@product2.id, [@variant1.id]]], workflow.abandoned_cart_products(only_product_and_variant_ids: true)
  end
end
