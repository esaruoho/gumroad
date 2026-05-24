# frozen_string_literal: true

require "test_helper"

class CardDataHandlingErrorTest < ActiveSupport::TestCase
  class WithMessageTest < ActiveSupport::TestCase
    setup do
      @subject = CardDataHandlingError.new("the-error-message")
    end

    test "message is accessible" do
      assert_equal "the-error-message", @subject.error_message
    end

    test "card error code is nil" do
      assert_nil @subject.card_error_code
    end

    test "is not a card error" do
      assert_equal false, @subject.is_card_error?
    end
  end

  class WithMessageAndCardCodeTest < ActiveSupport::TestCase
    setup do
      @subject = CardDataHandlingError.new("the-error-message", "card-error-code")
    end

    test "message is accessible" do
      assert_equal "the-error-message", @subject.error_message
    end

    test "card error code is accessible" do
      assert_equal "card-error-code", @subject.card_error_code
    end

    test "is a card error" do
      assert_equal true, @subject.is_card_error?
    end
  end
end
