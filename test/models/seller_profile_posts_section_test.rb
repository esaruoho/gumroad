# frozen_string_literal: true

require "test_helper"

class SellerProfilePostsSectionTest < ActiveSupport::TestCase
  test "validates json_data with the correct schema" do
    section = SellerProfilePostsSection.new(seller: users(:named_seller), shown_posts: [1])
    section.json_data["garbage"] = "should not be here"

    section.validate

    assert_equal "The property '#/' contains additional properties [\"garbage\"] outside of the schema when none are allowed",
                 section.errors.full_messages.to_sentence
  end
end
