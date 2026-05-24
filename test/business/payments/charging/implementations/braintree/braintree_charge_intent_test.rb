# frozen_string_literal: true

require "test_helper"

class BraintreeChargeIntentTest < ActiveSupport::TestCase
  setup do
    @braintree_charge = Object.new
    @intent = BraintreeChargeIntent.new(charge: @braintree_charge)
  end

  test "#succeeded? returns true" do
    assert_equal true, @intent.succeeded?
  end

  test "#requires_action? returns false" do
    assert_equal false, @intent.requires_action?
  end

  test "#charge returns the charge object it was initialized with" do
    assert_equal @braintree_charge, @intent.charge
  end
end
