# frozen_string_literal: true

require "test_helper"

class Charge::CreateServiceTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/charge/create_service_spec.rb
  # Blocker: Stripe Charge.create + payment_intent confirm + ChargeIntent factory chain under VCR. Live charge processor flow.
  test "TODO: migrate spec/services/charge/create_service_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
