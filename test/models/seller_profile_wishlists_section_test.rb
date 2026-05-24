# frozen_string_literal: true

require "test_helper"

class SellerProfileWishlistsSectionTest < ActiveSupport::TestCase
  test "validates json_data with the correct schema" do
    section = SellerProfileWishlistsSection.new(
      seller: users(:named_seller),
      shown_wishlists: [wishlists(:named_seller_wishlist).id],
    )
    section.json_data["garbage"] = "should not be here"

    section.validate

    assert_equal "The property '#/' contains additional properties [\"garbage\"] outside of the schema when none are allowed",
                 section.errors.full_messages.to_sentence

    section.json_data.delete("garbage")
    assert section.valid?
  end
end
