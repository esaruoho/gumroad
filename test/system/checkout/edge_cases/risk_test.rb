# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../system_test_case"
require_relative "../checkout_page"
require_relative "../stripe_test_cards"

# Risk scoring & seller suspension.
#
# Adversarial-actor surface: card testing, velocity attacks, pump-and-dumps,
# refund abuse, brand impersonation. These rules protect both Gumroad's
# Stripe relationship and legitimate sellers from being grouped with fraud.
#
# See docs/refund-chargeback-fraud-edge-cases.md §4.
class RiskTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: Card testing pattern unblocked, Stripe issues account warning
  def test_card_testing_pattern_5_failed_cards_60s_blocks_ip
    skip "Scaffolding"
  end

  # Production-incident class: Velocity check disabled, bot scrapes purchases through
  def test_velocity_check_10_purchases_1m_routes_to_review
    skip "Scaffolding"
  end

  # Production-incident class: High-risk MCC + high cart value passes silently, chargeback follows
  def test_high_risk_mcc_plus_high_value_elevates_radar_routes_review
    skip "Scaffolding"
  end

  # Production-incident class: Repeat-refund-abuse buyer reuses Gumroad freely, support manually flagging each time
  def test_repeat_refund_abuse_3_in_30d_flags_buyer
    skip "Scaffolding"
  end

  # Production-incident class: Pump-and-dump seller paid out before scheme detected
  def test_pump_and_dump_pattern_suspends_seller_holds_payout
    skip "Scaffolding"
  end

  # Production-incident class: Brand impersonation product never flagged, brand owner complaint hits CEO inbox
  def test_brand_impersonation_pattern_flags_compliance_review
    skip "Scaffolding"
  end

  # Production-incident class: Stolen-card test purchase credited to seller, dispute hits seller balance
  def test_stolen_card_success_credits_held_dispute_auto_conceded
    skip "Scaffolding"
  end

  # Production-incident class: Risky seller paid out, then refunds bounce back as negative balance loss
  def test_low_balance_fraud_check_holds_payout_pending_review
    skip "Scaffolding"
  end
end
