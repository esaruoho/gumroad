# frozen_string_literal: true

require "test_helper"

class CardDataHandlingModeTest < ActiveSupport::TestCase
  test "has the correct value for modes" do
    assert_equal "stripejs.0", CardDataHandlingMode::TOKENIZE_VIA_STRIPEJS
  end

  test "has the correct valid modes" do
    assert_includes CardDataHandlingMode::VALID_MODES, "stripejs.0"
  end

  test "maps each card data handling mode to the correct charge processor" do
    assert_equal StripeChargeProcessor.charge_processor_id, CardDataHandlingMode::VALID_MODES["stripejs.0"]
  end

  test "is_valid returns true for stripejs.0" do
    assert_equal true, CardDataHandlingMode.is_valid("stripejs.0")
  end

  test "is_valid returns false for a clearly invalid mode" do
    assert_equal false, CardDataHandlingMode.is_valid("jedi-mode")
  end

  test "is_valid returns false for a mix of valid and invalid modes" do
    assert_equal false, CardDataHandlingMode.is_valid("stripejs.0,jedi-mode")
  end

  test "get_card_data_handling_mode returns stripejs.0" do
    assert_equal "stripejs.0", CardDataHandlingMode.get_card_data_handling_mode(nil)
  end
end
