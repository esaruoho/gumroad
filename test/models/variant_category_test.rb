# frozen_string_literal: true

require "test_helper"

class VariantCategoryTest < ActiveSupport::TestCase
  setup do
    @product = links(:basic_user_product)
    # Use a product that has no pre-existing variant categories so we control the picture.
    @other_product = links(:another_seller_product)
  end

  # ----- scopes -----

  test ".is_tier_category returns variant categories with title 'Tier'" do
    # Fixtures already include two Tier categories (spc_tier_category,
    # variant_price_test_tier_category). Add a non-Tier category to confirm
    # the scope filters it out.
    VariantCategory.create!(link_id: @other_product.id, title: "versions")
    tier_titles = VariantCategory.is_tier_category.pluck(:title).uniq
    assert_equal ["Tier"], tier_titles
    assert_operator VariantCategory.is_tier_category.count, :>=, 2
  end

  # ----- #has_alive_grouping_variants_with_purchases? -----

  def build_purchase(link:, purchase_state: "successful", **extra)
    p = Purchase.new(link: link, seller: link.user, email: "vc-test-#{SecureRandom.hex(4)}@example.com",
                     purchase_state: purchase_state,
                     total_transaction_cents: link.price_cents,
                     displayed_price_cents: link.price_cents,
                     displayed_price_currency_type: "usd", price_cents: link.price_cents,
                     fee_cents: 0, **extra)
    cols = p.attributes.compact.merge("created_at" => Time.current, "updated_at" => Time.current)
    cols.delete("id")
    id = Purchase.insert(cols).rows.first&.first ||
         Purchase.connection.select_value("SELECT LAST_INSERT_ID()")
    Purchase.find(id)
  end

  def make_category(product:)
    VariantCategory.create!(link_id: product.id, title: "Category-#{SecureRandom.hex(2)}")
  end

  def make_variant(category:, with_file: false)
    v = Variant.new(variant_category: category, name: "v-#{SecureRandom.hex(2)}", flags: 0)
    v.save!(validate: false)
    if with_file
      file = category.link.product_files.create!(url: "#{S3_BASE_URL}specs/vc-#{SecureRandom.hex(2)}.pdf", position: 0)
      v.product_files << file
    end
    v
  end

  test "non-product-file grouping: returns false when category has no variants" do
    category = make_category(product: @other_product)
    assert_equal false, category.has_alive_grouping_variants_with_purchases?
  end

  test "non-product-file grouping: returns false when alive variants have no purchases" do
    category = make_category(product: @other_product)
    make_variant(category: category)
    assert_equal false, category.has_alive_grouping_variants_with_purchases?
  end

  test "non-product-file grouping: returns false even when variants have purchases (no product_files)" do
    category = make_category(product: @other_product)
    variant = make_variant(category: category)
    assert_equal false, category.has_alive_grouping_variants_with_purchases?

    purchase = build_purchase(link: @other_product)
    BaseVariantsPurchase.create!(purchase_id: purchase.id, base_variant_id: variant.id)
    assert_equal false, category.has_alive_grouping_variants_with_purchases?
  end

  test "non-product-file grouping: returns false when variants are deleted" do
    category = make_category(product: @other_product)
    variant = make_variant(category: category)
    variant.update!(deleted_at: Time.current)
    assert_equal false, category.has_alive_grouping_variants_with_purchases?

    purchase = build_purchase(link: @other_product)
    BaseVariantsPurchase.create!(purchase_id: purchase.id, base_variant_id: variant.id)
    assert_equal false, category.has_alive_grouping_variants_with_purchases?
  end

  test "with associated files: returns false when category has no variants" do
    category = make_category(product: @other_product)
    @other_product.product_files.create!(url: "#{S3_BASE_URL}specs/vc-a.pdf", position: 0)
    assert_equal false, category.has_alive_grouping_variants_with_purchases?
  end

  test "with associated files: returns false when variants have no purchases" do
    category = make_category(product: @other_product)
    variant = make_variant(category: category, with_file: true)
    assert_equal false, category.has_alive_grouping_variants_with_purchases?
  end

  test "with associated files: returns true when variants have successful purchases" do
    category = make_category(product: @other_product)
    variant = make_variant(category: category, with_file: true)

    %w[preorder_authorization_successful successful not_charged gift_receiver_purchase_successful].each do |state|
      purchase = build_purchase(link: @other_product, purchase_state: state)
      BaseVariantsPurchase.create!(purchase_id: purchase.id, base_variant_id: variant.id)
      assert_equal true, category.has_alive_grouping_variants_with_purchases?, "expected true for state=#{state}"
    end
  end

  test "with associated files: returns false when variants have only test/failed/in_progress purchases" do
    category = make_category(product: @other_product)
    variant = make_variant(category: category, with_file: true)

    %w[test_successful failed in_progress preorder_authorization_failed].each do |state|
      purchase = build_purchase(link: @other_product, purchase_state: state)
      BaseVariantsPurchase.create!(purchase_id: purchase.id, base_variant_id: variant.id)
    end
    assert_equal false, category.has_alive_grouping_variants_with_purchases?
  end

  test "with associated files: returns false when variants are deleted with no purchases" do
    category = make_category(product: @other_product)
    variant = make_variant(category: category, with_file: true)
    variant.update!(deleted_at: Time.current)
    assert_equal false, category.has_alive_grouping_variants_with_purchases?
  end

  test "with associated files: returns false when deleted variants have purchases" do
    category = make_category(product: @other_product)
    variant = make_variant(category: category, with_file: true)
    variant.update!(deleted_at: Time.current)
    assert_equal false, category.has_alive_grouping_variants_with_purchases?

    purchase = build_purchase(link: @other_product)
    BaseVariantsPurchase.create!(purchase_id: purchase.id, base_variant_id: variant.id)
    assert_equal false, category.has_alive_grouping_variants_with_purchases?
  end
end
