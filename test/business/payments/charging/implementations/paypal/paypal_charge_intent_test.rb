# frozen_string_literal: true

require "test_helper"

class PaypalChargeIntentTest < ActiveSupport::TestCase
  setup do
    @paypal_charge = Object.new
    @intent = PaypalChargeIntent.new(charge: @paypal_charge)
  end

  test "#succeeded? returns true" do
    assert_equal true, @intent.succeeded?
  end

  test "#requires_action? returns false" do
    assert_equal false, @intent.requires_action?
  end

  test "#charge returns the charge object it was initialized with" do
    assert_equal @paypal_charge, @intent.charge
  end
end
