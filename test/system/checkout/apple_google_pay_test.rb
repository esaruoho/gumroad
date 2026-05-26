# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../system_test_case"
require_relative "checkout_page"
require_relative "stripe_test_cards"


# Apple Pay / Google Pay via Stripe Payment Request Button.
#
# See docs/test-slow-rewrite-tracker.md for the full cluster index.
class ApplePayCheckoutTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: Button missing on Safari/iOS, buyer abandons
  def test_apple_pay_button_displays_on_supported_device
    skip "Scaffolding"
  end

  # Production-incident class: Apple Pay bypasses 3DS but our flow forces it, conversion lost
  def test_apple_pay_purchase_succeeds_no_3ds
    skip "Scaffolding"
  end

  # Production-incident class: Button missing in Chrome on Android
  def test_google_pay_button_displays_on_supported_device
    skip "Scaffolding"
  end

  # Production-incident class: Google Pay completes but no purchase row created
  def test_google_pay_purchase_succeeds
    skip "Scaffolding"
  end

  # Production-incident class: Apple Pay subscription mandate not stored; recurring fails
  def test_apple_pay_handles_subscription_correctly
    skip "Scaffolding"
  end

  # Production-incident class: Address from Apple Pay not synced; shipping label fails
  def test_apple_pay_billing_address_synced
    skip "Scaffolding"
  end
end
