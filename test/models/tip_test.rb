# frozen_string_literal: true

require "test_helper"

class TipTest < ActiveSupport::TestCase
  test "is valid when value_cents > 0" do
    tip = Tip.new(value_cents: 100, purchase: purchases(:auto_invoice_enabled_purchase))
    assert tip.valid?
  end

  test "is invalid when value_cents is zero" do
    tip = Tip.new(value_cents: 0, purchase: purchases(:auto_invoice_enabled_purchase))
    assert_not tip.valid?
    assert_includes tip.errors[:value_cents], "must be greater than 0"
  end
end
