# frozen_string_literal: true

require "test_helper"

class ChargePurchaseTest < ActiveSupport::TestCase
  test "validates presence of required attributes" do
    charge_purchase = ChargePurchase.new

    assert_not charge_purchase.valid?
    assert_equal({ charge: ["must exist"], purchase: ["must exist"] }, charge_purchase.errors.messages)
  end
end
