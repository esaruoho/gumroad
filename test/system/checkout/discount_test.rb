# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../system_test_case"
require_relative "checkout_page"
require_relative "stripe_test_cards"


# Discount + offer code application: percent, fixed, currency-locked, usage-limited, expiring, stacking rules.
#
# See docs/test-slow-rewrite-tracker.md for the full cluster index.
class DiscountTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: Discount applied after tax; oversells discount value
  def test_percent_off_discount_applies_to_total_before_tax
    skip "Scaffolding"
  end

  # Production-incident class: Fixed discount in wrong currency; buyer overcharged or undercharged
  def test_fixed_amount_discount_in_seller_currency
    skip "Scaffolding"
  end

  # Production-incident class: Usage limit ignored; promo bleeds revenue
  def test_offer_code_usage_limit_blocks_after_n_uses
    skip "Scaffolding"
  end

  # Production-incident class: Expired code accepted; revenue loss
  def test_expired_offer_code_rejected
    skip "Scaffolding"
  end

  # Production-incident class: Per-buyer cap ignored; one buyer drains the promo
  def test_offer_code_per_buyer_cap
    skip "Scaffolding"
  end

  # Production-incident class: Stacking allowed silently; oversells
  def test_stacking_two_offer_codes_disallowed
    skip "Scaffolding"
  end

  # Production-incident class: Auto-apply broken; promo never reaches buyers
  def test_default_discount_code_auto_applied
    skip "Scaffolding"
  end

  # Production-incident class: Zero discount bypasses checkout validation; corrupt purchase row
  def test_zero_discount_does_not_skip_validation
    skip "Scaffolding"
  end

  # Production-incident class: Invalid code returns 500; buyer abandons
  def test_invalid_offer_code_shows_clear_error
    skip "Scaffolding"
  end

  # Production-incident class: Tier discount applied to wrong tier price
  def test_offer_code_with_tiered_membership_applies_to_correct_tier
    skip "Scaffolding"
  end
end
