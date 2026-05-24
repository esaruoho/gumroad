# frozen_string_literal: true

require "test_helper"

class DisputeEvidence::CreateFromDisputeServiceTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/dispute_evidence/create_from_dispute_service_spec.rb
  # Blocker: Dispute + DisputeEvidence state machine + StripeChargeProcessor + customer/url_redirect/product_file chain. Service uploads ZIP of customer files to Stripe for dispute response.
  test "TODO: migrate spec/services/dispute_evidence/create_from_dispute_service_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
