# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../system_test_case"
require_relative "../checkout_page"
require_relative "../stripe_test_cards"

# Seller payouts blocked by money-flow events.
#
# Payouts are downstream of refunds, chargebacks, and fraud. Payout-block
# logic is what prevents Gumroad from paying out money that the seller will
# owe back the next day. Regressions here mean real cash loss.
#
# See docs/refund-chargeback-fraud-edge-cases.md §5.
class PayoutBlockTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: Pending dispute paid out, then dispute lost — Gumroad eats the loss
  def test_pending_dispute_holds_affected_balance_in_payout
    skip "Scaffolding"
  end

  # Production-incident class: Recent chargeback bypasses 21-day hold, balance paid out and clawed back
  def test_recent_chargeback_triggers_21_day_payout_hold
    skip "Scaffolding"
  end

  # Production-incident class: TOS suspended seller paid out anyway, support manually unwinding
  def test_tos_suspension_holds_payout_21_to_30_days
    skip "Scaffolding"
  end

  # Production-incident class: KYC-incomplete seller paid out, Stripe Connect flags account
  def test_kyc_compliance_hold_blocks_payout_pending_verification
    skip "Scaffolding"
  end

  # Production-incident class: Negative-balance seller paid out next cycle anyway, debt compounds
  def test_pending_refund_clawback_reduces_next_payout
    skip "Scaffolding"
  end

  # Production-incident class: Mass refund event paid out before balance reconciled, double loss
  def test_mass_refund_event_holds_all_related_payouts
    skip "Scaffolding"
  end

  # Production-incident class: Stripe Connect under review but Gumroad pays out anyway, Stripe debit
  def test_stripe_connect_under_review_blocks_payout
    skip "Scaffolding"
  end

  # Production-incident class: OFAC list update makes existing seller sanctioned, payout still released
  def test_seller_country_sanctions_change_holds_balance_blocks_sales
    skip "Scaffolding"
  end
end
