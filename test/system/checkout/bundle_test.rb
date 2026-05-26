# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../system_test_case"
require_relative "checkout_page"
require_relative "stripe_test_cards"


# Bundle products — multiple products sold as one transaction with a single line item. Bundle pricing is its own edge surface.
#
# See docs/test-slow-rewrite-tracker.md for the full cluster index.
class BundleCheckoutTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: Bundle purchase only grants partial access; buyer support burst
  def test_bundle_purchase_grants_access_to_all_included_products
    skip "Scaffolding"
  end

  # Production-incident class: Discount applied per-product, oversells the discount value
  def test_bundle_with_discount_applies_to_bundle_total_not_per_product
    skip "Scaffolding"
  end

  # Production-incident class: Refund revokes all bundle access; rest of products lost too
  def test_partial_refund_of_bundle_only_revokes_refunded_product
    skip "Scaffolding"
  end

  # Production-incident class: Bundle composition change post-purchase changes buyer's grants
  def test_bundle_pricing_locks_at_purchase_time
    skip "Scaffolding"
  end

  # Production-incident class: Bundle subscription billing schedule corrupted at purchase
  def test_bundle_with_subscription_inside_charges_subscription_separately
    skip "Scaffolding"
  end

  # Production-incident class: Mixed-currency bundle crashes at checkout
  def test_bundle_with_mixed_currency_components_falls_back_to_seller_currency
    skip "Scaffolding"
  end
end
