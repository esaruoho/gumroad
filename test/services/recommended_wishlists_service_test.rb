# frozen_string_literal: true

require "test_helper"

class RecommendedWishlistsServiceTest < ActiveSupport::TestCase
  setup do
    # Create 5 owners + recommendable wishlists, each with one wishlist_product.
    @owners = 5.times.map do |i|
      u = User.new(
        email: "rec_wishlist_owner_#{i}@example.com",
        password: "password_unused",
        user_risk_state: "not_reviewed",
        recommendation_type: "own_products"
      )
      u.confirmed_at = Time.current
      u.save!(validate: false)
      u
    end

    @products = 5.times.map do |i|
      Link.create!(
        user: @owners[i],
        name: "Wishlist product #{i}",
        unique_permalink: "rwp#{('a'.ord + i).chr}",
        price_cents: 100,
        purchase_type: 0,
        native_type: "digital",
        filetype: "link",
        filegroup: "url"
      )
    end

    @wishlists = 5.times.map do |i|
      w = Wishlist.create!(user: @owners[i], name: "Recommendable #{i}")
      WishlistProduct.create!(wishlist: w, product: @products[i], quantity: 1, rent: false)
      w.update_columns(recommendable: true, recent_follower_count: i)
      w
    end

    # 4 alternative "recommended" products owned by other users — used as curated_product_ids.
    @recommended_products = 4.times.map do |i|
      owner = User.new(
        email: "rec_curated_owner_#{i}@example.com",
        password: "password_unused",
        user_risk_state: "not_reviewed",
        recommendation_type: "own_products"
      )
      owner.confirmed_at = Time.current
      owner.save!(validate: false)
      Link.create!(
        user: owner,
        name: "Curated product #{i}",
        unique_permalink: "rcp#{('a'.ord + i).chr}",
        price_cents: 100,
        purchase_type: 0,
        native_type: "digital",
        filetype: "link",
        filegroup: "url"
      )
    end
  end

  test "returns wishlists ordered by recent_follower_count when no additional params are provided" do
    result = RecommendedWishlistsService.fetch(limit: 4, current_seller: nil)
    assert_equal 4, result.count
    assert_equal @wishlists.last(4).reverse, result.to_a
  end

  test "excludes wishlists owned by the current seller" do
    result = RecommendedWishlistsService.fetch(limit: 4, current_seller: @wishlists.last.user)
    assert_equal @wishlists.first(4).reverse, result.to_a
  end

  test "prioritizes wishlists with recommended products" do
    @wishlists.first(4).each_with_index do |w, i|
      WishlistProduct.create!(wishlist: w, product: @recommended_products[i], quantity: 1, rent: false)
    end

    result = RecommendedWishlistsService.fetch(limit: 4, current_seller: nil, curated_product_ids: @recommended_products.pluck(:id))
    assert_equal @wishlists.first(4).map(&:id).sort, result.map(&:id).sort
  end

  test "returns nothing if there are no product matches" do
    new_owner = User.new(
      email: "rec_extra_owner@example.com",
      password: "password_unused",
      user_risk_state: "not_reviewed",
      recommendation_type: "own_products"
    )
    new_owner.confirmed_at = Time.current
    new_owner.save!(validate: false)
    extra_product = Link.create!(
      user: new_owner,
      name: "Extra product",
      unique_permalink: "rwex",
      price_cents: 100,
      purchase_type: 0,
      native_type: "digital",
      filetype: "link",
      filegroup: "url"
    )

    result = RecommendedWishlistsService.fetch(limit: 4, current_seller: nil, curated_product_ids: [extra_product.id])
    assert_empty result.to_a
  end

  test "fills remaining slots with non-matching wishlists if not enough matches" do
    WishlistProduct.create!(wishlist: @wishlists.first, product: @recommended_products.second, quantity: 1, rent: false)

    result = RecommendedWishlistsService.fetch(limit: 4, current_seller: nil, curated_product_ids: @recommended_products.pluck(:id))
    assert_equal [@wishlists.first, *@wishlists.last(3).reverse], result.to_a
  end

  test "filters wishlists by taxonomy_id" do
    taxonomy = Taxonomy.create!(slug: "rec-wishlist-taxonomy")
    taxonomy_product = Link.create!(
      user: @owners.first,
      name: "Taxonomy product",
      unique_permalink: "rwtx",
      price_cents: 100,
      purchase_type: 0,
      native_type: "digital",
      filetype: "link",
      filegroup: "url",
      taxonomy: taxonomy
    )
    taxonomy_wishlist = Wishlist.create!(user: @owners.first, name: "Taxonomy wishlist")
    WishlistProduct.create!(wishlist: taxonomy_wishlist, product: taxonomy_product, quantity: 1, rent: false)
    taxonomy_wishlist.update_columns(recommendable: true)

    result = RecommendedWishlistsService.fetch(limit: 4, current_seller: nil, taxonomy_id: taxonomy.id)
    assert_equal [taxonomy_wishlist], result.to_a
  end

  test "returns nothing if there are no taxonomy matches" do
    empty_taxonomy = Taxonomy.create!(slug: "empty-rec-taxonomy")
    result = RecommendedWishlistsService.fetch(limit: 4, current_seller: nil, taxonomy_id: empty_taxonomy.id)
    assert_empty result.to_a
  end
end
