# frozen_string_literal: true

require "test_helper"

class SendWishlistUpdatedEmailsJobTest < ActiveSupport::TestCase
  setup do
    @wishlist = wishlists(:named_seller_wishlist)
    @wishlist_product = wishlist_products(:named_seller_wishlist_product)
  end

  test "returns early when no matching wishlist_products are alive" do
    sent = []
    CustomerLowPriorityMailer.stub(:wishlist_updated, ->(*_a) {
      m = Object.new; m.define_singleton_method(:deliver_later) { |*_, **__| sent << :w }; m
    }) do
      SendWishlistUpdatedEmailsJob.new.perform(@wishlist.id, [-1])
    end
    assert_empty sent
  end

  test "noop when wishlist has no followers" do
    sent = []
    CustomerLowPriorityMailer.stub(:wishlist_updated, ->(*_a) {
      m = Object.new; m.define_singleton_method(:deliver_later) { |*_, **__| sent << :w }; m
    }) do
      SendWishlistUpdatedEmailsJob.new.perform(@wishlist.id, [@wishlist_product.id])
    end
    assert_empty sent
    assert_not_nil @wishlist.reload.followers_last_contacted_at
  end

  test "enqueues mailer for each follower with new products" do
    follower_user = users(:basic_user)
    # WishlistFollower model: needs wishlist + follower_user; bypass validation for fixture-free row.
    follower = WishlistFollower.new(wishlist: @wishlist, follower_user: follower_user,
                                     created_at: 10.days.ago)
    follower.save!(validate: false)
    # wishlist_product was created recently — newer than follower.created_at.
    @wishlist_product.update_columns(created_at: 1.day.ago)

    sent = []
    CustomerLowPriorityMailer.stub(:wishlist_updated, ->(fid, n) {
      m = Object.new
      m.define_singleton_method(:deliver_later) { |*_a, **_kw| sent << [fid, n] }
      m
    }) do
      SendWishlistUpdatedEmailsJob.new.perform(@wishlist.id, [@wishlist_product.id])
    end
    assert_equal 1, sent.size
    assert_equal follower.id, sent.first.first
    assert_equal 1, sent.first.last
  end
end
