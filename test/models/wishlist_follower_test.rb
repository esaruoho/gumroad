require "test_helper"

class WishlistFollowerTest < ActiveSupport::TestCase
  setup do
    @wishlist = wishlists(:named_seller_wishlist)
    @follower = users(:basic_user)
  end

  test "validates uniqueness of follower" do
    first_follower = WishlistFollower.create!(wishlist: @wishlist, follower_user: @follower)

    second_follower = WishlistFollower.new(wishlist: @wishlist, follower_user: @follower)
    assert_not second_follower.valid?
    assert_equal "Follower user is already following this wishlist.", second_follower.errors.full_messages.sole

    second_follower.wishlist = wishlists(:basic_user_wishlist)
    # basic_user_wishlist is owned by basic_user (=@follower) — can't follow own wishlist
    # use a different wishlist instead: create a new one owned by another user
    another_wishlist = Wishlist.create!(user: users(:another_seller), name: "Another wishlist")
    second_follower.wishlist = another_wishlist
    assert second_follower.valid?

    second_follower.wishlist = @wishlist
    first_follower.mark_deleted!
    assert second_follower.valid?
  end

  test "prevents a user from following their own wishlist" do
    wishlist_follower = WishlistFollower.new(wishlist: @wishlist, follower_user: @wishlist.user)
    assert_not wishlist_follower.valid?
    assert_equal "You cannot follow your own wishlist.", wishlist_follower.errors.full_messages.sole
  end
end
