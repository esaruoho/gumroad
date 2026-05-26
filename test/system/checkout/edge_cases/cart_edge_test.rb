# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../system_test_case"
require_relative "../checkout_page"
require_relative "../stripe_test_cards"

# Cart-level edge cases.
#
# Mixed-currency carts, $0 carts, sub-minimum carts, and dynamic discount
# recalculation. These are the cart-builder bugs that snag buyers between
# add-to-cart and checkout-submit.
#
# See docs/checkout-edge-cases.md §5.
class CartEdgeTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: Mixed-currency cart crashes checkout instead of degrading gracefully
  def test_mixed_currency_cart_falls_back_to_usd_with_notice
    skip "Scaffolding"
  end

  # Production-incident class: Shipping charged per line-item instead of once per cart
  def test_digital_plus_shipped_cart_shipping_charged_once
    skip "Scaffolding"
  end

  # Production-incident class: $0 cart still calls Stripe, leaving orphaned payment intent
  def test_zero_total_cart_no_stripe_call_creates_zero_purchase
    skip "Scaffolding"
  end

  # Production-incident class: $0.30 cart hits Stripe minimum and shows obscure 500 error
  def test_below_stripe_minimum_blocked_with_clear_error
    skip "Scaffolding"
  end

  # Production-incident class: Quantity change applies stale discount, buyer overcharged
  def test_discount_then_quantity_change_recalculates_correctly
    skip "Scaffolding"
  end

  # Production-incident class: Abandoned cart recovered via email but state lost, buyer re-enters everything
  def test_abandoned_cart_recovered_state_preserved
    skip "Scaffolding"
  end
end
