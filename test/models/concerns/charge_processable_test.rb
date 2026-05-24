# frozen_string_literal: true

require "test_helper"

class ChargeProcessableTest < ActiveSupport::TestCase
  class TestSubject
    include ChargeProcessable
    attr_accessor :charge_processor_id

    def initialize(charge_processor_id)
      @charge_processor_id = charge_processor_id
    end
  end

  test "#stripe_charge_processor? returns true when charge_processor_id is stripe" do
    assert_equal true, TestSubject.new(StripeChargeProcessor.charge_processor_id).stripe_charge_processor?
  end

  test "#stripe_charge_processor? returns false when charge_processor_id is not stripe" do
    assert_equal false, TestSubject.new(PaypalChargeProcessor.charge_processor_id).stripe_charge_processor?
  end

  test "#stripe_charge_processor? returns false when charge_processor_id is nil" do
    assert_equal false, TestSubject.new(nil).stripe_charge_processor?
  end

  test "#paypal_charge_processor? returns true when charge_processor_id is paypal" do
    assert_equal true, TestSubject.new(PaypalChargeProcessor.charge_processor_id).paypal_charge_processor?
  end

  test "#paypal_charge_processor? returns false when charge_processor_id is not paypal" do
    assert_equal false, TestSubject.new(StripeChargeProcessor.charge_processor_id).paypal_charge_processor?
  end

  test "#paypal_charge_processor? returns false when charge_processor_id is nil" do
    assert_equal false, TestSubject.new(nil).paypal_charge_processor?
  end

  test "#braintree_charge_processor? returns true when charge_processor_id is braintree" do
    assert_equal true, TestSubject.new(BraintreeChargeProcessor.charge_processor_id).braintree_charge_processor?
  end

  test "#braintree_charge_processor? returns false when charge_processor_id is not braintree" do
    assert_equal false, TestSubject.new(StripeChargeProcessor.charge_processor_id).braintree_charge_processor?
  end

  test "#braintree_charge_processor? returns false when charge_processor_id is nil" do
    assert_equal false, TestSubject.new(nil).braintree_charge_processor?
  end
end
