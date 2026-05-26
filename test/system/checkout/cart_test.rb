# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../system_test_case"
require_relative "checkout_page"
require_relative "stripe_test_cards"


# Multi-item cart flows — add, remove, modify, persist across sessions. The cart system is shared by Universal Cart (one Stripe charge for multiple sellers).
#
# See docs/test-slow-rewrite-tracker.md for the full cluster index.
class CartCheckoutTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: Universal Cart charge fails to split correctly between sellers
  def test_add_two_products_to_cart_checkout_charges_both_sellers
    skip "Scaffolding"
  end

  # Production-incident class: Removed item still charged; buyer sees ghost line item
  def test_remove_item_from_cart_recomputes_total
    skip "Scaffolding"
  end

  # Production-incident class: Quantity change reset on page reload; buyer abandons
  def test_change_quantity_in_cart_persists
    skip "Scaffolding"
  end

  # Production-incident class: Cart cleared when session refreshed; buyer loses items, abandons
  def test_cart_persists_across_session
    skip "Scaffolding"
  end

  # Production-incident class: Mixed cart fails on subscription validation, blocks one-time purchase too
  def test_cart_with_subscription_plus_one_time
    skip "Scaffolding"
  end

  # Production-incident class: Empty cart URL crashes instead of redirecting
  def test_empty_cart_redirects_back_to_discover
    skip "Scaffolding"
  end
end
