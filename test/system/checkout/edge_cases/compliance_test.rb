# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../system_test_case"
require_relative "../checkout_page"
require_relative "../stripe_test_cards"

# Compliance & risk edge cases.
#
# OFAC sanctions, high-risk MCC tags, Stripe Radar flags, and refund routing
# on declined cards. These are the scenarios that put Gumroad's Stripe
# relationship and payment-processor agreements at risk if they regress.
#
# See docs/checkout-edge-cases.md §7.
class ComplianceTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: High-risk MCC stripped from Stripe metadata, Radar can't score
  def test_high_risk_mcc_5816_digital_goods_metadata_tagged
    skip "Scaffolding"
  end

  # Production-incident class: OFAC-sanctioned country reaches Stripe, triggering account-level audit
  def test_ofac_sanctioned_country_blocked_at_country_detection
    skip "Scaffolding"
  end

  # Production-incident class: Radar-flagged card silently charged, no support notification
  def test_radar_flagged_card_soft_decline_notifies_support
    skip "Scaffolding"
  end

  # Production-incident class: Refund issued as store credit despite buyer's card being declined later
  def test_refund_within_30_days_routes_to_original_card_not_store_credit
    skip "Scaffolding"
  end
end
