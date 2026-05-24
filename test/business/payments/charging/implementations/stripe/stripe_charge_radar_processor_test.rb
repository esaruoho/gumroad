# frozen_string_literal: true

require "test_helper"

class StripeChargeRadarProcessorTest < ActiveSupport::TestCase
  test "skipped: VCR-required" do
    skip "StripeChargeRadarProcessor spec is :vcr tagged and exercises Stripe radar event lifecycle (Stripe::Charge.retrieve / Refund.create) against the Stripe sandbox via VCR cassettes plus FactoryBot factories for Purchase. VCR is not yet wired into Minitest. Covered by RSpec."
  end
end
