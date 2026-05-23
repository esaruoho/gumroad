# frozen_string_literal: true

require "test_helper"

class CardParamsHelperTest < ActionView::TestCase
  test "get_card_data_handling_mode returns mode when valid" do
    assert_equal "stripejs.0", CardParamsHelper.get_card_data_handling_mode(card_data_handling_mode: "stripejs.0")
  end

  test "get_card_data_handling_mode returns nil when invalid" do
    assert_nil CardParamsHelper.get_card_data_handling_mode(card_data_handling_mode: "jedi-force")
  end

  test "check_for_errors returns nil with no errors" do
    assert_nil CardParamsHelper.check_for_errors(card_data_handling_mode: "stripejs.0")
  end

  test "check_for_errors returns nil with invalid card data handling mode" do
    assert_nil CardParamsHelper.check_for_errors(card_data_handling_mode: "jedi-force")
  end

  test "check_for_errors returns CardDataHandlingError with stripe errors" do
    params = {
      card_data_handling_mode: "stripejs.0",
      stripe_error: { message: "The card was declined.", code: "card_declined" }
    }
    err = CardParamsHelper.check_for_errors(params)
    assert_kind_of CardDataHandlingError, err
    assert_equal "The card was declined.", err.error_message
    assert_equal "card_declined", err.card_error_code
  end

  test "build_chargeable returns nil with invalid card data handling mode" do
    assert_nil CardParamsHelper.build_chargeable(card_data_handling_mode: "jedi-force")
  end

  test "build_chargeable delegates to ChargeProcessor with valid mode" do
    params = { card_data_handling_mode: "stripejs.0" }
    chargeable = Object.new
    ChargeProcessor.stub(:get_chargeable_for_params, ->(p, gum_co) { assert_equal params, p; chargeable }) do
      assert_same chargeable, CardParamsHelper.build_chargeable(params)
    end
  end
end
