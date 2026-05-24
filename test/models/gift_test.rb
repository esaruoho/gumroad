# frozen_string_literal: true

require "test_helper"

class GiftTest < ActiveSupport::TestCase
  test "removes leading/trailing spaces in emails" do
    gift = Gift.create!(gifter_email: " abc@def.com ", giftee_email: " foo@bar.com ")
    assert_equal "abc@def.com", gift.gifter_email
    assert_equal "foo@bar.com", gift.giftee_email
  end

  test "errors if giftee email is invalid" do
    gift = Gift.new(gifter_email: "gifter@gumroad.com", giftee_email: "foo")
    assert_not gift.valid?
    assert_includes gift.errors.full_messages, "Giftee email is invalid"
  end

  test "errors if gifter email is invalid" do
    gift = Gift.new(gifter_email: "foo", giftee_email: "giftee@gumroad.com")
    assert_not gift.valid?
    assert_includes gift.errors.full_messages, "Gifter email is invalid"
  end
end
