# frozen_string_literal: true

require "test_helper"

class WishlistTest < ActiveSupport::TestCase
  setup do
    @wishlist = wishlists(:named_seller_wishlist)
    @user = users(:basic_user)
  end

  # ----- .find_by_url_slug -----

  test ".find_by_url_slug finds a wishlist" do
    assert_equal @wishlist, Wishlist.find_by_url_slug(@wishlist.url_slug)
  end

  test ".find_by_url_slug returns nil when the wishlist does not exist" do
    assert_nil Wishlist.find_by_url_slug("foo")
  end

  # ----- #url_slug -----

  test "#url_slug returns a readable URL path plus the ID" do
    @wishlist.update!(name: "My Wishlist")
    assert_equal "my-wishlist-#{@wishlist.external_id_numeric}", @wishlist.url_slug
  end

  # ----- #followed_by? -----

  test "#followed_by? returns true when the user is following the wishlist" do
    WishlistFollower.create!(wishlist: @wishlist, follower_user: @user)
    assert_equal true, @wishlist.followed_by?(@user)
  end

  test "#followed_by? returns false when the user has unfollowed the wishlist" do
    WishlistFollower.create!(wishlist: @wishlist, follower_user: @user, deleted_at: Time.current)
    assert_equal false, @wishlist.followed_by?(@user)
  end

  test "#followed_by? returns false when the user is not following the wishlist" do
    assert_equal false, @wishlist.followed_by?(@user)
  end

  # ----- #wishlist_products_for_email -----

  test "#wishlist_products_for_email returns alive products when no email has been sent yet" do
    # Remove existing fixture products to control the timeline cleanly.
    @wishlist.wishlist_products.delete_all
    old_product = @wishlist.wishlist_products.create!(product: links(:another_seller_product), created_at: 1.day.ago, quantity: 1, rent: false)
    new_product = @wishlist.wishlist_products.create!(product: links(:pdf_stamping_product), created_at: 1.hour.ago, quantity: 1, rent: false)
    deleted = @wishlist.wishlist_products.create!(product: links(:audience_physical_product), created_at: 1.hour.ago, quantity: 1, rent: false, deleted_at: Time.current)

    result = @wishlist.wishlist_products_for_email.to_a
    assert_equal [old_product, new_product].sort_by(&:id), result.sort_by(&:id)
    assert_not_includes result, deleted
  end

  test "#wishlist_products_for_email returns alive products added after the last email when an email has been sent" do
    @wishlist.wishlist_products.delete_all
    @wishlist.update!(followers_last_contacted_at: 12.hours.ago)
    old_product = @wishlist.wishlist_products.create!(product: links(:another_seller_product), created_at: 1.day.ago, quantity: 1, rent: false)
    new_product = @wishlist.wishlist_products.create!(product: links(:pdf_stamping_product), created_at: 1.hour.ago, quantity: 1, rent: false)

    assert_equal [new_product], @wishlist.wishlist_products_for_email.to_a
  end

  # ----- #update_recommendable -----

  test "#update_recommendable sets recommendable to true when there are alive wishlist products" do
    @wishlist.update!(name: "My Wishlist")
    @wishlist.update_recommendable
    assert_equal true, @wishlist.recommendable
  end

  test "#update_recommendable sets recommendable to false when there are no alive wishlist products" do
    @wishlist.update!(name: "My Wishlist")
    @wishlist.wishlist_products.delete_all
    @wishlist.update_recommendable
    assert_equal false, @wishlist.recommendable
  end

  test "#update_recommendable sets recommendable to false when name is adult" do
    @wishlist.update!(name: "My Wishlist")
    AdultKeywordDetector.stub(:adult?, ->(text) { text == @wishlist.name }) do
      @wishlist.update_recommendable
    end
    assert_equal false, @wishlist.recommendable
  end

  test "#update_recommendable sets recommendable to false when description is adult" do
    @wishlist.update!(name: "My Wishlist", description: "some description")
    AdultKeywordDetector.stub(:adult?, ->(text) { text == @wishlist.description }) do
      @wishlist.update_recommendable
    end
    assert_equal false, @wishlist.recommendable
  end

  test "#update_recommendable sets recommendable to false when discover is opted out" do
    @wishlist.update!(name: "My Wishlist")
    @wishlist.discover_opted_out = true
    @wishlist.update_recommendable
    assert_equal false, @wishlist.recommendable
  end

  test "#update_recommendable sets recommendable to false when name is a default auto-generated one" do
    @wishlist.update!(name: "My Wishlist")
    @wishlist.name = "Wishlist 1"
    @wishlist.update_recommendable
    assert_equal false, @wishlist.recommendable
  end

  test "#update_recommendable saves the record when save is true" do
    @wishlist.update!(name: "My Wishlist")
    @wishlist.discover_opted_out = true
    @wishlist.update_recommendable(save: true)
    assert_equal false, @wishlist.reload.recommendable
  end

  test "#update_recommendable does not save the record when save is false" do
    @wishlist.update!(name: "My Wishlist")
    # Prime DB recommendable=true so we can prove an in-memory false-flip isn't persisted.
    @wishlist.update_recommendable(save: true)
    assert_equal true, @wishlist.reload.recommendable

    @wishlist.discover_opted_out = true
    @wishlist.update_recommendable(save: false)
    assert_equal false, @wishlist.recommendable
    assert_equal true, @wishlist.reload.recommendable
  end
end
