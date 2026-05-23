# frozen_string_literal: true

require "test_helper"

class Checkout::Upsells::ProductPresenterTest < ActiveSupport::TestCase
  setup do
    @product = links(:upsell_test_product)
    @presenter = Checkout::Upsells::ProductPresenter.new(@product)
  end

  test "returns product properties hash" do
    assert_equal(
      {
        id: @product.external_id,
        permalink: @product.unique_permalink,
        name: "Test Product",
        price_cents: 1000,
        currency_code: "usd",
        review_count: 1,
        average_rating: 5.0,
        native_type: "ebook",
        thumbnail_url: nil,
        options: []
      },
      @presenter.product_props
    )
  end

  test "includes thumbnail_url when product has a thumbnail" do
    thumbnail = Thumbnail.new(product: @product)
    thumbnail.save!(validate: false)
    @product.reload
    assert_equal thumbnail.url, @presenter.product_props[:thumbnail_url]
  end
end
