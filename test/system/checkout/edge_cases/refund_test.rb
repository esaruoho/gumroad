# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../system_test_case"
require_relative "../checkout_page"
require_relative "../stripe_test_cards"

# Refund happy & rough paths.
#
# Buyer-initiated refunds across full, partial, post-payout, multi-currency,
# replaced-card, closed-account, $0, and idempotent-double-refund scenarios.
#
# See docs/refund-chargeback-fraud-edge-cases.md §1.
class RefundTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: Refund issued but Stripe charge not refunded, buyer charges back instead
  def test_refund_within_window_issues_stripe_refund_debits_balance
    skip "Scaffolding"
  end

  # Production-incident class: Refund silently issued past policy window, seller blindsided
  def test_refund_outside_window_routes_to_support_no_auto_refund
    skip "Scaffolding"
  end

  # Production-incident class: Partial refund double-charges balance for the unrefunded portion
  def test_partial_refund_debits_balance_by_partial_amount
    skip "Scaffolding"
  end

  # Production-incident class: Subscription mid-period refund leaves access intact, buyer keeps content for free
  def test_subscription_mid_period_refund_revokes_access_prorates_refund
    skip "Scaffolding"
  end

  # Production-incident class: Negative balance from post-payout refund never clawed back, Gumroad eats the loss
  def test_refund_after_payout_cleared_flags_balance_for_clawback
    skip "Scaffolding"
  end

  # Production-incident class: Multi-currency refund converted to USD, buyer loses FX delta
  def test_refund_in_buyer_local_currency_no_fx_drift
    skip "Scaffolding"
  end

  # Production-incident class: $0 purchase refund triggers Stripe call, orphaned refund row
  def test_refund_of_zero_total_purchase_no_stripe_call_audit_trail_logged
    skip "Scaffolding"
  end

  # Production-incident class: Buyer removed card after purchase, refund silently fails
  def test_refund_with_replaced_card_routes_via_customer_id
    skip "Scaffolding"
  end

  # Production-incident class: Refund to closed account fails silently, no fallback
  def test_refund_to_closed_account_falls_back_to_store_credit
    skip "Scaffolding"
  end

  # Production-incident class: Race condition double-refunds, support manually clawing back
  def test_multi_refund_within_24h_idempotency_key_prevents_double
    skip "Scaffolding"
  end
end
