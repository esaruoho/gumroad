# frozen_string_literal: true

require "test_helper"

class DeleteWishlistProductsJobTest < ActiveSupport::TestCase
  setup do
    @product = links(:basic_user_product)
    @wishlist_product = wishlist_products(:basic_user_wishlist_product)
    @unrelated_wishlist_product = wishlist_products(:named_seller_wishlist_product)
  end

  test "deletes associated wishlist products" do
    @product.mark_deleted!
    DeleteWishlistProductsJob.new.perform(@product.id)
    assert @wishlist_product.reload.deleted?
    refute @unrelated_wishlist_product.reload.deleted?
  end

  test "does nothing if the product was not actually deleted" do
    DeleteWishlistProductsJob.new.perform(@product.id)
    refute @wishlist_product.reload.deleted?
  end
end
