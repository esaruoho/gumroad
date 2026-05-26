# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../system_test_case"
require_relative "checkout_page"
require_relative "stripe_test_cards"


# Post-purchase upsell flow — Stripe payment intent reuse for instant-charge upsells.
#
# See docs/test-slow-rewrite-tracker.md for the full cluster index.
class UpsellCheckoutTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: Upsell never shown; conversion revenue lost silently
  def test_upsell_offered_after_main_purchase
    skip "Scaffolding"
  end

  # Production-incident class: Upsell creates separate intent; UX shows 'pay again'
  def test_upsell_accepted_charges_saved_card_immediately
    skip "Scaffolding"
  end

  # Production-incident class: Decline path creates charge anyway; double-bill
  def test_upsell_declined_does_not_charge
    skip "Scaffolding"
  end

  # Production-incident class: Offer code ignored on upsell; buyer paid full price
  def test_upsell_with_offer_code_applies_discount
    skip "Scaffolding"
  end

  # Production-incident class: Upsell crashes when main was subscription
  def test_upsell_after_subscription_purchase_works
    skip "Scaffolding"
  end

  # Production-incident class: Cross-seller upsell crosses Universal Cart boundaries unsafely
  def test_upsell_cross_seller_blocked
    skip "Scaffolding"
  end
end
