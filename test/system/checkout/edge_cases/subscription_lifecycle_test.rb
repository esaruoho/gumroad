# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../system_test_case"
require_relative "../checkout_page"
require_relative "../stripe_test_cards"

# Subscription lifecycle edge cases.
#
# Subscriptions accumulate state across many events (signup, renewal, decline,
# grace period, upgrade, pause, cancel, migration). The bugs are almost always
# at state transitions, not within any single charge.
#
# See docs/checkout-edge-cases.md §4.
class SubscriptionLifecycleTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: 2nd-charge decline silently cancels with no grace period
  def test_first_charge_succeeds_second_declines_grace_period_then_cancel
    skip "Scaffolding"
  end

  # Production-incident class: Paused subscription still charged at next interval
  def test_paused_mid_cycle_no_charge_access_retained
    skip "Scaffolding"
  end

  # Production-incident class: Mid-cycle upgrade charged in seller currency, ignoring buyer-local lock
  def test_mid_cycle_upgrade_charged_prorated_in_buyer_currency
    skip "Scaffolding"
  end

  # Production-incident class: Failed installment payment doesn't stop subsequent installments
  def test_installment_plan_payment_2_of_4_fails_no_further_charges
    skip "Scaffolding"
  end

  # Production-incident class: End-of-period cancel revokes access before period ends
  def test_cancel_at_period_end_access_retained_until_then
    skip "Scaffolding"
  end

  # Production-incident class: Stripe customer migration double-charges or strands subscription
  def test_stripe_customer_migrated_subscription_survives_no_double_bill
    skip "Scaffolding"
  end
end
