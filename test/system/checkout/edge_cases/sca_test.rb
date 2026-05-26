# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../system_test_case"
require_relative "../checkout_page"
require_relative "../stripe_test_cards"

# SCA / 3DS edge cases.
#
# Strong Customer Authentication (PSD2 + RBI India) is the most frequent silent
# regression area: a frontend tweak or webhook plumbing change breaks 3DS and
# the failure only shows up in a tiny % of European/Indian transactions.
#
# See docs/checkout-edge-cases.md §2.
class ScaTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: 3DS challenge surfaces but completion isn't acked, no purchase row
  def test_3ds_required_user_completes_challenge_succeeds
    skip "Scaffolding"
  end

  # Production-incident class: User abandons 3DS but charge still goes through
  def test_3ds_required_user_abandons_no_charge_no_purchase_row
    skip "Scaffolding"
  end

  # Production-incident class: Indian buyer mandate not stored, recurring 2nd charge declines
  def test_india_rbi_mandate_stored_on_first_charge
    skip "Scaffolding"
  end

  # Production-incident class: 2nd recurring charge fails silently, subscription stays active
  def test_india_rbi_recurring_decline_flips_subscription_to_failed
    skip "Scaffolding"
  end

  # Production-incident class: Off-session renewal triggers SCA but buyer never notified
  def test_off_session_renewal_triggers_sca_buyer_emailed
    skip "Scaffolding"
  end

  # Production-incident class: Returning customer with saved card hits SCA but UX assumes frictionless
  def test_saved_card_returning_customer_sca_challenge
    skip "Scaffolding"
  end

  # Production-incident class: Low-value EU transactions hitting 3DS unnecessarily, hurting conversion
  def test_low_value_eu_transaction_under_30_eur_exempt_from_3ds
    skip "Scaffolding"
  end

  # Production-incident class: Soft decline + 3DS path goes into infinite retry loop
  def test_soft_decline_falls_back_to_frictionless_retry
    skip "Scaffolding"
  end
end
