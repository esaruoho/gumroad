# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../system_test_case"
require_relative "checkout_page"
require_relative "stripe_test_cards"


# Core checkout happy paths — digital product, single item, US buyer/US seller. The load-bearing flow that 80%+ of GMV runs through.
#
# See docs/test-slow-rewrite-tracker.md for the full cluster index.
class CoreCheckoutTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: Happy-path checkout broken silently — every other test is built on this passing
  def test_digital_product_visa_us_buyer_succeeds
    skip "Scaffolding"
  end

  # Production-incident class: Logged-in checkout bypasses session-aware billing logic
  def test_digital_product_logged_in_user_succeeds
    skip "Scaffolding"
  end

  # Production-incident class: Post-purchase signup link broken, buyer never gets library access
  def test_digital_product_guest_then_signup_succeeds
    skip "Scaffolding"
  end

  # Production-incident class: Display total != Stripe charge — buyer-facing UX bug surfaces as billing complaint
  def test_display_total_matches_charge_amount
    skip "Scaffolding"
  end

  # Production-incident class: Receipt email never sent; buyer thinks purchase failed
  def test_receipt_email_sent_after_success
    skip "Scaffolding"
  end

  # Production-incident class: Library row created but download URL not pre-signed; buyer hits 404
  def test_download_link_works_immediately
    skip "Scaffolding"
  end

  # Production-incident class: Quantity multiplier ignored at Stripe level; buyer charged for 1 of 3
  def test_multi_quantity_purchase
    skip "Scaffolding"
  end

  # Production-incident class: Required custom field skipped; seller misses fulfillment info
  def test_custom_field_captured_on_purchase
    skip "Scaffolding"
  end
end
