# frozen_string_literal: true

require "test_helper"

class Order::ChargeServiceTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/order/charge_service_spec.rb
  # Blocker: 103 FactoryBot refs; full Stripe SCA + multi-purchase order flow under VCR. Requires stripe-mock + payment_intent confirm round-trips.
  test "TODO: migrate spec/services/order/charge_service_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
