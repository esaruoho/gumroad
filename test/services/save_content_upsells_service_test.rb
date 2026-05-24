# frozen_string_literal: true

require "test_helper"

class SaveContentUpsellsServiceTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @product = links(:upsell_test_product)
    @variant_category = VariantCategory.create!(link: @product, title: "Variants")
    @variant = Variant.create!(variant_category: @variant_category, name: "v1")
  end

  test "from_html creates an upsell" do
    content = %(<p>Content with upsell</p><upsell-card productid="#{@product.external_id}" variantid="#{@variant.external_id}"></upsell-card>)
    old_content = "<p>Old content</p>"

    assert_difference "Upsell.count", 1 do
      SaveContentUpsellsService.new(seller: @seller, content:, old_content:).from_html
    end

    upsell = Upsell.last
    assert_equal @seller, upsell.seller
    assert_equal @product.id, upsell.product_id
    assert_equal @variant.id, upsell.variant_id
    assert_equal true, upsell.is_content_upsell
    assert_equal true, upsell.cross_sell
  end

  test "from_html adds id to the upsell card" do
    content = %(<upsell-card productid="#{@product.external_id}" variantid="#{@variant.external_id}"></upsell-card>)
    result = Nokogiri::HTML.fragment(SaveContentUpsellsService.new(seller: @seller, content:, old_content: "<p>old</p>").from_html)
    assert result.at_css("upsell-card")["id"].present?
  end

  test "from_html with discount creates an offer code" do
    content = %(<upsell-card productid="#{@product.external_id}" discount='{"type":"fixed","cents":500}'></upsell-card>)
    assert_difference "OfferCode.count", 1 do
      SaveContentUpsellsService.new(seller: @seller, content:, old_content: "<p>old</p>").from_html
    end

    offer_code = OfferCode.last
    assert_equal 500, offer_code.amount_cents
    assert_nil offer_code.amount_percentage
    assert_equal [@product.id], offer_code.product_ids
  end

  test "from_html marks upsell and offer code as deleted when removed" do
    offer_code = OfferCode.create!(user: @seller, code: "html-rm-code", amount_cents: 100, product_ids: [@product.id])
    upsell = Upsell.create!(seller: @seller, product: @product, is_content_upsell: true, cross_sell: true, offer_code:)

    old_content = %(<p>Old content</p><upsell-card id="#{upsell.external_id}"></upsell-card>)
    content = "<p>Content without upsell</p>"

    SaveContentUpsellsService.new(seller: @seller, content:, old_content:).from_html

    assert upsell.reload.deleted?
    assert offer_code.reload.deleted?
  end

  test "from_rich_content creates an upsell" do
    old_content = [{ "type" => "paragraph", "content" => "Old content" }]
    content = [
      { "type" => "paragraph", "content" => "Content with upsell" },
      { "type" => "upsellCard", "attrs" => { "productId" => @product.external_id, "variantId" => @variant.external_id } }
    ]

    assert_difference "Upsell.count", 1 do
      SaveContentUpsellsService.new(seller: @seller, content:, old_content:).from_rich_content
    end

    upsell = Upsell.last
    assert_equal @seller, upsell.seller
    assert_equal @product.id, upsell.product_id
    assert_equal @variant.id, upsell.variant_id
    assert_equal true, upsell.is_content_upsell
    assert_equal true, upsell.cross_sell
  end

  test "from_rich_content adds id to the upsell node" do
    content = [
      { "type" => "upsellCard", "attrs" => { "productId" => @product.external_id, "variantId" => @variant.external_id } }
    ]
    result = SaveContentUpsellsService.new(seller: @seller, content:, old_content: []).from_rich_content
    assert result.last["attrs"]["id"].present?
  end

  test "from_rich_content with discount creates a percent offer code" do
    content = [
      {
        "type" => "upsellCard",
        "attrs" => {
          "productId" => @product.external_id,
          "discount" => { "type" => "percent", "percents" => 20 }
        }
      }
    ]
    SaveContentUpsellsService.new(seller: @seller, content:, old_content: []).from_rich_content

    offer_code = OfferCode.last
    assert_nil offer_code.amount_cents
    assert_equal 20, offer_code.amount_percentage
    assert_equal [@product.id], offer_code.product_ids
  end

  test "from_rich_content marks upsell and offer code as deleted when removed" do
    offer_code = OfferCode.create!(user: @seller, code: "rich-rm-code", amount_cents: 100, product_ids: [@product.id])
    upsell = Upsell.create!(seller: @seller, product: @product, is_content_upsell: true, cross_sell: true, offer_code:)

    old_content = [
      { "type" => "paragraph", "content" => "Old content" },
      { "type" => "upsellCard", "attrs" => { "id" => upsell.external_id } }
    ]
    content = [{ "type" => "paragraph", "content" => "Content without upsell" }]

    SaveContentUpsellsService.new(seller: @seller, content:, old_content:).from_rich_content

    assert upsell.reload.deleted?
    assert offer_code.reload.deleted?
  end
end
