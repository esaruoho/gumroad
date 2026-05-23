# frozen_string_literal: true

require "test_helper"

class RecommendedProducts::DiscoverServiceTest < ActiveSupport::TestCase
  setup do
    @purchaser = users(:discover_service_purchaser)
    @alive_products = [
      links(:discover_service_product_one),
      links(:discover_service_product_two),
      links(:discover_service_product_three),
    ]
    @all_products = @alive_products + [
      links(:discover_service_product_archived),
      links(:discover_service_product_deleted),
    ]
    @products_relation = Link.where(id: @all_products.map(&:id))
    @recommender_model_name = RecommendedProductsService::MODEL_SALES
  end

  test ".fetch initializes with the correct arguments and calls product_infos" do
    cart_product = links(:discover_service_cart_product)
    captured = nil
    original_new = RecommendedProducts::DiscoverService.method(:new)
    fake_instance = Object.new
    fake_instance.define_singleton_method(:product_infos) { [] }
    RecommendedProducts::DiscoverService.define_singleton_method(:new) do |**kwargs|
      captured = kwargs
      fake_instance
    end
    begin
      RecommendedProducts::DiscoverService.fetch(
        purchaser: @purchaser,
        cart_product_ids: [cart_product.id],
        recommender_model_name: @recommender_model_name,
      )
    ensure
      RecommendedProducts::DiscoverService.singleton_class.send(:remove_method, :new)
      RecommendedProducts::DiscoverService.define_singleton_method(:new, original_new)
    end

    assert_equal @purchaser, captured[:purchaser]
    assert_equal [cart_product.id], captured[:cart_product_ids]
    assert_equal @recommender_model_name, captured[:recommender_model_name]
    assert_equal RecommendationType::GUMROAD_PRODUCTS_FOR_YOU_RECOMMENDATION, captured[:recommended_by]
    assert_equal Product::Layout::DISCOVER, captured[:target]
    assert_equal RecommendedProducts::BaseService::NUMBER_OF_RESULTS, captured[:limit]
  end

  test "#product_infos returns empty array without purchaser and without cart_product_ids" do
    result = RecommendedProducts::DiscoverService.fetch(
      purchaser: nil,
      cart_product_ids: [],
      recommender_model_name: @recommender_model_name,
    )
    assert_equal [], result
  end

  test "#product_infos returns product infos without a purchaser but with cart_product_ids" do
    cart_product = links(:discover_service_cart_product)
    captured_args = nil
    relation = @products_relation
    fetch_stub = ->(**kwargs) {
      captured_args = kwargs
      relation
    }

    RecommendedProductsService.stub(:fetch, fetch_stub) do
      result = RecommendedProducts::DiscoverService.fetch(
        purchaser: nil,
        cart_product_ids: [cart_product.id],
        recommender_model_name: @recommender_model_name,
      )

      assert_equal RecommendedProductsService::MODEL_SALES, captured_args[:model]
      assert_equal [cart_product.id], captured_args[:ids]
      assert_equal [cart_product.id], captured_args[:exclude_ids]
      assert_equal RecommendedProducts::BaseService::NUMBER_OF_RESULTS, captured_args[:number_of_results]
      assert_nil captured_args[:user_ids]

      returned_products = result.map(&:product)
      assert_equal @alive_products.map(&:id).sort, returned_products.map(&:id).sort
      assert_equal [nil], result.map(&:affiliate_id).uniq
      assert_equal [RecommendationType::GUMROAD_PRODUCTS_FOR_YOU_RECOMMENDATION], result.map(&:recommended_by).uniq
      assert_equal [@recommender_model_name], result.map(&:recommender_model_name).uniq
      assert_equal [Product::Layout::DISCOVER], result.map(&:target).uniq
    end
  end

  test "#product_infos returns empty array when purchaser has no purchases and no cart_product_ids" do
    purchaser_no_purchases = users(:discover_service_seller)  # any user without purchases works
    result = RecommendedProducts::DiscoverService.fetch(
      purchaser: purchaser_no_purchases,
      cart_product_ids: [],
      recommender_model_name: @recommender_model_name,
    )
    assert_equal [], result
  end

  test "#product_infos returns product infos when purchaser has purchases" do
    captured_args = nil
    relation = @products_relation
    fetch_stub = ->(**kwargs) {
      captured_args = kwargs
      relation
    }

    RecommendedProductsService.stub(:fetch, fetch_stub) do
      result = RecommendedProducts::DiscoverService.fetch(
        purchaser: @purchaser,
        cart_product_ids: [],
        recommender_model_name: @recommender_model_name,
      )

      purchase_link_id = purchases(:discover_service_purchaser_purchase).link_id
      assert_equal [purchase_link_id], captured_args[:ids]
      assert_equal [purchase_link_id], captured_args[:exclude_ids]
      returned_products = result.map(&:product)
      assert_equal @alive_products.map(&:id).sort, returned_products.map(&:id).sort
    end
  end

  test "#product_infos excludes NSFW products from results" do
    nsfw_product = links(:discover_service_nsfw_product)
    nsfw_relation = Link.where(id: [nsfw_product.id] + @all_products.map(&:id))

    RecommendedProductsService.stub(:fetch, nsfw_relation) do
      result = RecommendedProducts::DiscoverService.fetch(
        purchaser: @purchaser,
        cart_product_ids: [],
        recommender_model_name: @recommender_model_name,
      )
      returned_ids = result.map { _1.product.id }
      assert_not_includes returned_ids, nsfw_product.id
      assert_equal @alive_products.map(&:id).sort, returned_ids.sort
    end
  end
end
