# frozen_string_literal: true

require "test_helper"

class Charge::CreateServiceTest < ActiveSupport::TestCase
  test "TODO: migrate spec/services/charge/create_service_spec.rb (11 FB refs, :vcr Stripe charge intent end-to-end)" do
    skip "Awaiting fixtures migration: spec drives Order::CreateService → 5 products across 2 sellers → real Stripe PaymentIntent via VCR + stripe-mock for success and decline branches; depends on chargeable factory + StripePaymentMethodHelper + ChargeProcessor.create_payment_intent_or_charge!. Not tractable as a fixture conversion."
  end
end
