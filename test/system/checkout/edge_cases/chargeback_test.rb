# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../system_test_case"
require_relative "../checkout_page"
require_relative "../stripe_test_cards"

# Chargebacks & disputes.
#
# Stripe dispute webhook arrives → evidence submission → win/lose → balance
# reconciliation. Each chargeback costs $15-25 in fees and erodes acceptance
# rate; silent regressions here are extremely expensive.
#
# See docs/refund-chargeback-fraud-edge-cases.md §2.
class ChargebackTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: Dispute webhook arrives but no row created, evidence deadline missed
  def test_stripe_dispute_created_webhook_creates_dispute_row
    skip "Scaffolding"
  end

  # Production-incident class: Evidence not auto-submitted within 7-day window, default loss
  def test_auto_submit_evidence_within_7_day_window
    skip "Scaffolding"
  end

  # Production-incident class: Won dispute balance not restored
  def test_dispute_won_balance_restored
    skip "Scaffolding"
  end

  # Production-incident class: Lost dispute balance not debited, Gumroad books wrong revenue
  def test_dispute_lost_balance_debited_chargeback_ratio_incremented
    skip "Scaffolding"
  end

  # Production-incident class: Buyer-withdrawn dispute treated as loss, balance not restored
  def test_dispute_withdrawn_balance_restored_no_ratio_impact
    skip "Scaffolding"
  end

  # Production-incident class: Pre-arbitration escalation missed, no evidence resubmitted
  def test_pre_arbitration_escalation_new_evidence_cycle
    skip "Scaffolding"
  end

  # Production-incident class: Inquiry-only dispute treated as full chargeback, balance hit unnecessarily
  def test_inquiry_only_dispute_response_no_balance_hit
    skip "Scaffolding"
  end

  # Production-incident class: Stripe acceptance threshold crossed silently, account terminated
  def test_chargeback_ratio_exceeds_threshold_flags_account_review
    skip "Scaffolding"
  end

  # Production-incident class: Chargeback on subscription cancels entire history, double-refunds
  def test_subscription_chargeback_only_disputed_charge_refunded
    skip "Scaffolding"
  end

  # Production-incident class: Repeat-chargeback buyer reuses Gumroad freely, future fraud unblocked
  def test_multi_chargeback_same_buyer_flags_fraud_blocks_future_purchases
    skip "Scaffolding"
  end
end
