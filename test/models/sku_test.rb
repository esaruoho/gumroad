# frozen_string_literal: true

require "test_helper"

class SkuTest < ActiveSupport::TestCase
  setup do
    seller = users(:another_seller)
    @product = Link.new(user: seller, name: "Sku Test Product", filegroup: "url", price_cents: 100)
    @product.save(validate: false)
  end

  def make_sku(**attrs)
    Sku.create!({ link: @product, name: "Red", price_difference_cents: 0, flags: 0 }.merge(attrs))
  end

  test "MaxPurchaseCount concern automatically constrains the max_purchase_count" do
    sku = make_sku
    sku.update!(max_purchase_count: 999_999_999_999)
    assert_equal 10_000_000, sku.max_purchase_count
    sku.update!(max_purchase_count: -100)
    assert_equal 0, sku.max_purchase_count
  end

  test "sku_category_name returns the proper category name given 2 variants" do
    VariantCategory.create!(link: @product, title: "Size")
    VariantCategory.create!(link: @product, title: "Color")
    sku = make_sku
    assert_equal "Size - Color", sku.sku_category_name
  end

  test "sku_category_name returns the proper category name given 1 variant" do
    VariantCategory.create!(link: @product, title: "Size")
    cat2 = VariantCategory.create!(link: @product, title: "Color")
    sku = make_sku
    cat2.update_attribute(:deleted_at, Time.current)
    assert_equal "Size", sku.sku_category_name
  end

  test "as_json includes custom_sku" do
    sku = make_sku(custom_sku: "customSKU")
    json = sku.as_json(for_views: true)
    assert_equal "customSKU", json["custom_sku"]
  end

  test "as_json does not include custom_sku if it does not exist" do
    sku = make_sku(custom_sku: "customSKU")
    sku.update_attribute(:custom_sku, nil)
    json = sku.as_json(for_views: true)
    assert_nil json["custom_sku"]
  end

  test "#to_option returns a hash of attributes for use in checkout" do
    sku = make_sku(name: "Red")
    assert_equal(
      {
        id: sku.external_id,
        name: sku.name,
        quantity_left: nil,
        description: "",
        price_difference_cents: 0,
        recurrence_price_values: nil,
        is_pwyw: false,
        duration_in_minutes: nil,
      },
      sku.to_option
    )
  end

  test "#to_option_for_product returns a hash of attributes" do
    sku = make_sku(name: "Red")
    assert_equal(
      {
        id: sku.external_id,
        name: sku.name,
        quantity_left: nil,
        description: "",
        price_difference_cents: 0,
        recurrence_price_values: nil,
        is_pwyw: false,
        duration_in_minutes: nil,
      },
      sku.to_option_for_product
    )
  end

  test "enqueues Elasticsearch update if price_difference_cents changes" do
    sku = make_sku(custom_sku: "customSKU", price_difference_cents: 20)

    enqueued = []
    capture_enqueue_index(enqueued) do
      sku.update!(price_difference_cents: 10)
    end

    assert_includes enqueued, ["available_price_cents"]
  end

  test "does not enqueue Elasticsearch update if prices have not changed" do
    sku = make_sku(custom_sku: "customSKU", price_difference_cents: 20)

    enqueued = []
    capture_enqueue_index(enqueued) do
      sku.update!(price_difference_cents: 20)
    end

    refute_includes enqueued, ["available_price_cents"]
  end

  private
    def capture_enqueue_index(sink)
      stub_mod = Module.new do
        define_method(:enqueue_index_update_for) do |fields|
          sink << fields
        end
      end
      Link.prepend(stub_mod)
      yield
    ensure
      # Module.prepend cannot be undone but the override only writes to local sink which is fine.
    end
end
