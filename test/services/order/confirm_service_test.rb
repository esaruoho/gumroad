# frozen_string_literal: true

require "test_helper"

class Order::ConfirmServiceTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/order/confirm_service_spec.rb
  # Blocker: VCR-tagged; runs Order::CreateService + Order::ChargeService + Order::ConfirmService end-to-end with StripePaymentMethodHelper.success_with_sca. Requires stripe-mock SCA + 3DS confirmation round-trips.
  test "TODO: migrate spec/services/order/confirm_service_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
