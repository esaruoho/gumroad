# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Charge spec (530 LOC, 80 create() refs) is
# `:vcr`-tagged top-level and includes StripeChargesHelper. The whole
# combined-charge lifecycle (purchase aggregation, refund, dispute) threads
# through real Stripe Charge / PaymentIntent objects under VCR cassettes
# that aren't ported to the Minitest harness. Without VCR + StripeChargesHelper
# every test crashes at charge creation. Out of scope for mechanical model
# backfill (same family as BalanceTransaction / Charge::Disputable).
#
# Original spec: spec/models/charge_spec.rb
class ChargeTest < ActiveSupport::TestCase
  test "TODO: migrate — :vcr + StripeChargesHelper + combined-charge lifecycle" do
    skip "Top-level :vcr; 80 create() refs through StripeChargesHelper + Stripe Charge/PaymentIntent + purchase aggregation/refund/dispute. Out of scope for mechanical model backfill."
  end
end
