# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../system_test_case"
require_relative "../checkout_page"
require_relative "../stripe_test_cards"

# Early fraud warnings (Stripe Radar EFW).
#
# Acting on EFWs prevents ~80% of downstream chargebacks. This is the single
# highest-leverage pre-emptive fraud surface; silent regressions here directly
# convert to chargeback fees + acceptance-rate damage.
#
# See docs/refund-chargeback-fraud-edge-cases.md §3.
class FraudWarningTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: EFW arrives in window but no auto-refund, chargeback follows next week
  def test_efw_in_window_auto_refunds_notifies_support
    skip "Scaffolding"
  end

  # Production-incident class: EFW outside window auto-acted-on against policy
  def test_efw_outside_window_routes_to_support_no_auto_action
    skip "Scaffolding"
  end

  # Production-incident class: Non-actionable EFW triggers refund anyway, false positive cost
  def test_efw_actionable_false_no_op_logs_only
    skip "Scaffolding"
  end

  # Production-incident class: Subscription EFW cancels all history, double-refunds
  def test_efw_subscription_auto_cancels_refunds_only_disputed_charge
    skip "Scaffolding"
  end

  # Production-incident class: EFW followed by chargeback causes double-refund
  def test_efw_then_chargeback_no_double_refund
    skip "Scaffolding"
  end

  # Production-incident class: EFW on already-refunded purchase issues second refund
  def test_efw_on_already_refunded_purchase_no_op
    skip "Scaffolding"
  end
end
