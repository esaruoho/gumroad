# frozen_string_literal: true

require "test_helper"

class SellerProfileRichTextSectionTest < ActiveSupport::TestCase
  test "validates json_data with the correct schema" do
    section = SellerProfileRichTextSection.new(seller: users(:named_seller))
    section.json_data["garbage"] = "should not be here"

    section.validate

    assert_equal "The property '#/' contains additional properties [\"garbage\"] outside of the schema when none are allowed",
                 section.errors.full_messages.to_sentence
  end

  test "limits the size of the text object" do
    section = SellerProfileRichTextSection.new(seller: users(:named_seller), text: { text: "a" * 500_000 })
    assert_not section.valid?
    assert_equal "Text is too large", section.errors.full_messages.to_sentence
  end
end
