# frozen_string_literal: true

require "test_helper"

class RecommendedProducts::CheckoutServiceTest < ActiveSupport::TestCase
  setup do
    @purchaser = users(:discover_service_purchaser)
    @seller = users(:discover_service_seller)
    @seller.update_columns(recommendation_type: User::RecommendationType::OWN_PRODUCTS)
    @cart_product = links(:discover_service_cart_product)
    @purchased_product = links(:discover_service_product_one)
    @recommended_product = links(:discover_service_product_two)
    @fallback_product = links(:discover_service_product_three)
    @archived_product = links(:discover_service_product_archived)
    @deleted_product = links(:discover_service_product_deleted)
    @nsfw_product = links(:discover_service_nsfw_product)
    @recommender_model_name = RecommendedProductsService::MODEL_SALES
  end

  test ".fetch_for_cart initializes with checkout defaults" do
    captured = capture_new_call do
      RecommendedProducts::CheckoutService.fetch_for_cart(
        purchaser: @purchaser,
        cart_product_ids: [@cart_product.id],
        recommender_model_name: @recommender_model_name,
        limit: 5
      )
    end

    assert_equal @purchaser, captured[:purchaser]
    assert_equal [@cart_product.id], captured[:cart_product_ids]
    assert_equal @recommender_model_name, captured[:recommender_model_name]
    assert_equal RecommendationType::GUMROAD_MORE_LIKE_THIS_RECOMMENDATION, captured[:recommended_by]
    assert_equal Product::Layout::PROFILE, captured[:target]
    assert_equal 5, captured[:limit]
    assert_nil captured[:recommendation_type]
  end

  test ".fetch_for_receipt initializes with receipt defaults" do
    captured = capture_new_call do
      RecommendedProducts::CheckoutService.fetch_for_receipt(
        purchaser: @purchaser,
        receipt_product_ids: [@purchased_product.id],
        recommender_model_name: @recommender_model_name,
        limit: 5
      )
    end

    assert_equal @purchaser, captured[:purchaser]
    assert_equal [@purchased_product.id], captured[:cart_product_ids]
    assert_equal @recommender_model_name, captured[:recommender_model_name]
    assert_equal RecommendationType::GUMROAD_RECEIPT_RECOMMENDATION, captured[:recommended_by]
    assert_equal Product::Layout::PROFILE, captured[:target]
    assert_equal 5, captured[:limit]
  end

  test "passes seller ids for cart sellers that allow own-product recommendations" do
    captured_args = nil
    fetch_stub = ->(**kwargs) {
      captured_args = kwargs
      Link.where(id: @recommended_product.id)
    }

    RecommendedProductsService.stub(:fetch, fetch_stub) do
      result = RecommendedProducts::CheckoutService.fetch_for_cart(
        purchaser: @purchaser,
        cart_product_ids: [@cart_product.id],
        recommender_model_name: @recommender_model_name,
        limit: 1
      )

      assert_equal @recommender_model_name, captured_args[:model]
      assert_equal [@cart_product.id, @purchased_product.id], captured_args[:ids]
      assert_equal [@cart_product.id, @purchased_product.id], captured_args[:exclude_ids]
      assert_equal RecommendedProducts::BaseService::NUMBER_OF_RESULTS, captured_args[:number_of_results]
      assert_equal [@seller.id], captured_args[:user_ids]

      assert_equal [@recommended_product], result.map(&:product)
      assert_equal [RecommendationType::GUMROAD_MORE_LIKE_THIS_RECOMMENDATION], result.map(&:recommended_by).uniq
      assert_equal [@recommender_model_name], result.map(&:recommender_model_name).uniq
      assert_equal [Product::Layout::PROFILE], result.map(&:target).uniq
    end
  end

  test "fills missing recommendation slots from seller products" do
    RecommendedProductsService.stub(:fetch, Link.where(id: @recommended_product.id)) do
      result = nil
      calls = with_search_products_returning(products: Link.where(id: @fallback_product.id)) do
        result = RecommendedProducts::CheckoutService.fetch_for_cart(
          purchaser: @purchaser,
          cart_product_ids: [@cart_product.id],
          recommender_model_name: @recommender_model_name,
          limit: 2
        )
      end

      assert_equal(
        [
          {
            size: 1,
            sort: ProductSortKey::FEATURED,
            user_id: [@seller.id],
            is_alive_on_profile: true,
            exclude_ids: [@cart_product.id, @purchased_product.id, @recommended_product.id]
          }
        ],
        calls
      )

      assert_equal [@recommended_product, @fallback_product], result.map(&:product)
    end
  end

  test "does not return recommendations for sellers that opted out" do
    @seller.update_columns(recommendation_type: User::RecommendationType::NO_RECOMMENDATIONS)

    RecommendedProductsService.stub(:fetch, Link.where(id: @recommended_product.id)) do
      result = RecommendedProducts::CheckoutService.fetch_for_cart(
        purchaser: @purchaser,
        cart_product_ids: [@cart_product.id],
        recommender_model_name: @recommender_model_name,
        limit: 5
      )

      assert_equal [], result
    end
  end

  test "filters out deleted and archived recommended products" do
    relation = Link.where(id: [@recommended_product.id, @fallback_product.id, @archived_product.id, @deleted_product.id])

    RecommendedProductsService.stub(:fetch, relation) do
      result = nil
      with_search_products_returning(products: Link.none) do
        result = RecommendedProducts::CheckoutService.fetch_for_cart(
          purchaser: @purchaser,
          cart_product_ids: [@cart_product.id],
          recommender_model_name: @recommender_model_name,
          limit: 5
        )
      end

      assert_equal [@recommended_product.id, @fallback_product.id].sort, result.map { _1.product.id }.sort
    end
  end

  test "filters adult recommendations for affiliate-style carts without adult products" do
    @seller.update_columns(recommendation_type: User::RecommendationType::GUMROAD_AFFILIATES_PRODUCTS)

    RecommendedProductsService.stub(:fetch, Link.where(id: @nsfw_product.id)) do
      result = nil
      with_search_products_returning(products: Link.none) do
        result = RecommendedProducts::CheckoutService.fetch_for_cart(
          purchaser: @purchaser,
          cart_product_ids: [@cart_product.id],
          recommender_model_name: @recommender_model_name,
          limit: 1
        )
      end

      assert_equal [], result
    end
  end

  test "allows adult recommendations when the cart contains an adult product" do
    @seller.update_columns(recommendation_type: User::RecommendationType::GUMROAD_AFFILIATES_PRODUCTS)
    @cart_product.update_columns(flags: @cart_product.flags | Link.flag_mapping["flags"][:is_adult])

    RecommendedProductsService.stub(:fetch, Link.where(id: @nsfw_product.id)) do
      result = RecommendedProducts::CheckoutService.fetch_for_cart(
        purchaser: @purchaser,
        cart_product_ids: [@cart_product.id],
        recommender_model_name: @recommender_model_name,
        limit: 1
      )

      assert_equal [@nsfw_product], result.map(&:product)
      assert_equal [RecommendationType::GUMROAD_MORE_LIKE_THIS_RECOMMENDATION], result.map(&:recommended_by).uniq
    end
  end

  private
    def capture_new_call
      captured = nil
      original_new = RecommendedProducts::CheckoutService.method(:new)
      fake_instance = Object.new
      fake_instance.define_singleton_method(:result) { [] }
      RecommendedProducts::CheckoutService.define_singleton_method(:new) do |**kwargs|
        captured = kwargs
        fake_instance
      end
      yield
      captured
    ensure
      RecommendedProducts::CheckoutService.singleton_class.send(:remove_method, :new)
      RecommendedProducts::CheckoutService.define_singleton_method(:new, original_new)
    end

    def with_search_products_returning(products:)
      calls = []
      had_own_search_products = RecommendedProducts::CheckoutService.instance_methods(false).include?(:search_products) ||
        RecommendedProducts::CheckoutService.private_instance_methods(false).include?(:search_products)
      original_method = RecommendedProducts::CheckoutService.instance_method(:search_products)
      RecommendedProducts::CheckoutService.define_method(:search_products) do |params|
        calls << params
        { products: }
      end
      RecommendedProducts::CheckoutService.send(:private, :search_products)

      yield
      calls
    ensure
      RecommendedProducts::CheckoutService.remove_method(:search_products)
      if had_own_search_products
        RecommendedProducts::CheckoutService.define_method(:search_products, original_method)
        RecommendedProducts::CheckoutService.send(:private, :search_products)
      end
    end
end
