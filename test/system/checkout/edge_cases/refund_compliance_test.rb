# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../system_test_case"
require_relative "../checkout_page"
require_relative "../stripe_test_cards"

# Cross-cutting compliance & accounting around refunds.
#
# VAT/sales-tax refunds, 1099-K threshold edges, revenue recognition across
# month boundaries, installment refund handling, FX drift on refund, and
# GDPR data deletion vs. retention windows.
#
# These regressions produce audit findings — finance, compliance, and
# data-protection teams own the impact, not engineering directly.
#
# See docs/refund-chargeback-fraud-edge-cases.md §6.
class RefundComplianceTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: VAT portion of refund debited from seller balance, VAT reporting wrong
  def test_eu_vat_refund_returned_to_buyer_not_debited_from_seller_balance
    skip "Scaffolding"
  end

  # Production-incident class: 1099-K filed for seller below net threshold due to refunds, IRS amendment burden
  def test_1099k_threshold_uses_net_of_refunds
    skip "Scaffolding"
  end

  # Production-incident class: Refund booked in refund month, revenue recognition fails GAAP audit
  def test_refund_crosses_month_boundary_books_in_original_sale_month
    skip "Scaffolding"
  end

  # Production-incident class: Installment plan refunded across all installments, future ones still charged
  def test_installment_plan_refund_only_paid_installments_cancels_future
    skip "Scaffolding"
  end

  # Production-incident class: FX drift on refund eats buyer balance, perceived as overcharge
  def test_refund_at_original_fx_rate_gumroad_bears_drift
    skip "Scaffolding"
  end

  # Production-incident class: GDPR deletion strips dispute evidence before window closes, default loss
  def test_gdpr_deletion_with_active_dispute_retains_until_resolved
    skip "Scaffolding"
  end
end
