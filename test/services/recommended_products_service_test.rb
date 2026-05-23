# frozen_string_literal: true

require "test_helper"

class RecommendedProductsServiceTest < ActiveSupport::TestCase
  setup do
    @seller = users(:recommended_products_seller)
    @sample_product = links(:recommended_sample_product)
    @product1 = links(:recommended_product_one)
    @product2 = links(:recommended_product_two)
    @product3 = links(:recommended_product_three)

    CachedSalesRelatedProductsInfo.delete_all
    UpdateCachedSalesRelatedProductsInfosJob.new.perform(@sample_product.id)
  end

  test ".fetch returns an ActiveRecord::Relation sorted by customer count and excludes non-alive products" do
    results = RecommendedProductsService.fetch(
      model: RecommendedProductsService::MODEL_SALES,
      ids: [@sample_product.id],
    )

    assert_kind_of ActiveRecord::Relation, results
    assert_equal [@product1, @product2, @product3], results.to_a
  end

  test ".fetch excludes products with the specified IDs" do
    results = RecommendedProductsService.fetch(
      model: RecommendedProductsService::MODEL_SALES,
      ids: [@sample_product.id],
      exclude_ids: [@product1.id],
    )

    assert_equal [@product2, @product3], results.to_a
  end

  test ".fetch only returns products that belong to the specified users" do
    results = RecommendedProductsService.fetch(
      model: RecommendedProductsService::MODEL_SALES,
      ids: [@sample_product.id],
      user_ids: [@seller.id],
    )

    assert_equal [@product1, @product2], results.to_a
  end

  test ".fetch returns at most the specified number of products" do
    results = RecommendedProductsService.fetch(
      model: RecommendedProductsService::MODEL_SALES,
      ids: [@sample_product.id],
      number_of_results: 1,
    )

    assert_equal [@product1], results.to_a
  end
end
