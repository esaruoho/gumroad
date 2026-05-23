# frozen_string_literal: true

require "test_helper"

class SendableToKindleTest < ActiveSupport::TestCase
  setup do
    @product_file = product_files(:signed_url_helper_pdf)
  end

  test "raises an error if the kindle email is invalid" do
    invalid_emails = [
      "example@example.org",
      "EXAMPLE123.-23[]@KINDLE.COM",
      ".a12@KINDLE.COM",
      "example..23@KINDLE.COM",
      "example..@KINDLE.COM",
      "\"example.23\"@KINDLE.COM",
      "example123456789" * 16 + "@KINDLE.COM",
    ]
    invalid_emails.each do |email|
      err = assert_raises(ArgumentError) { @product_file.send_to_kindle(email) }
      assert_equal "Please enter a valid Kindle email address", err.message
    end
  end

  test "does not raise an error if the kindle email is valid" do
    valid_emails = %w[
      example@kindle.com
      ExAmple123@KINDLE.com
      ExAmple.123@KINDLE.com
      ExAmple_123@KINDLE.com
      ExAmple__123@KINDLE.com
      ExAmple-123@KINDLE.com
      ExAmple--123@KINDLE.com
    ]
    valid_emails.each do |email|
      assert_nothing_raised { @product_file.send_to_kindle(email) }
    end
  end
end
