# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/modules/payment/stats_spec.rb (37 FactoryBot refs, 280 lines).
#
# Blocker for batch A backfill: spec is tagged `:vcr` and the whole shape is
# `Payouts.create_payments_for_balances_up_to_date_for_users(..., PayoutProcessorType::PAYPAL, ...)`
# inside `travel_to` blocks, then asserting on `Payment.last.revenue_by_link`.
# Every example needs: `:singaporean_user_with_compliance_info` (a 5-table
# user_compliance_info + bank_account + tos_agreement chain), `:direct_affiliate`
# joins, `create(:purchase_in_progress, ...).process!` (which goes through the
# full charge pipeline), `create(:chargeable)` (Stripe live token stub),
# VCR cassettes for the PayPal payout creation, and stubs for
# `Purchase#create_dispute_evidence_if_needed!` and `User#unpaid_balance_cents`.
# Skill rule P-M3 (mailers, transferable to modules): >40 FB w/ heavy state
# machine → skip-batch. Also touches Payment + PayPal payout cassettes none
# of which the Minitest lane carries. Out of scope for batch A.
class ModulesPaymentStatsTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/modules/payment/stats_spec.rb — :vcr-tagged Payouts.create_payments_for_balances pipeline; needs singaporean_user_with_compliance_info fixture chain, Stripe/PayPal VCR cassettes, and Purchase#process! chargeable stubs."
  end
end
