# frozen_string_literal: true

require "test_helper"

class InstantPayoutsServiceTest < ActiveSupport::TestCase
  test "TODO: migrate spec/services/instant_payouts_service_spec.rb (16 FB refs, VCR + Stripe live account + compliance + 7+ balances)" do
    skip "Awaiting fixtures migration: VCR-recorded Stripe account creation flow (compliant_user, tos_agreement, user_compliance_info, ach_account_stripe_succeed, merchant_account_stripe), Stripe::Balance/Transfer interactions, multi-balance scheduling — not tractable as a fixture stub without redesigning the service test."
  end
end
