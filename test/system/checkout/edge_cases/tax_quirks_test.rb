# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../system_test_case"
require_relative "../checkout_page"
require_relative "../stripe_test_cards"

# Tax oddities — VAT-exemption, US economic nexus, jurisdiction-mapping, and
# inclusive vs exclusive pricing display.
#
# These are tax-law edge cases that produce both compliance risk (under-collecting)
# and conversion risk (over-collecting + scaring off buyers).
#
# See docs/checkout-edge-cases.md §6.
class TaxQuirksTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # Production-incident class: B2B buyer charged VAT despite valid VATIN
  def test_eu_b2b_buyer_with_valid_vatin_no_vat_charged
    skip "Scaffolding"
  end

  # Production-incident class: Invalid VATIN treated as valid, under-collecting VAT
  def test_eu_b2b_buyer_with_invalid_vatin_charges_vat_logs_error
    skip "Scaffolding"
  end

  # Production-incident class: US sales tax origin/destination rules inverted by state
  def test_us_sales_tax_ca_origin_based_vs_ny_destination_based
    skip "Scaffolding"
  end

  # Production-incident class: B2B invoice missing reverse-charge line, accounting audit fail
  def test_eu_b2b_reverse_charge_line_on_invoice
    skip "Scaffolding"
  end

  # Production-incident class: Digital goods to EU under OSS not applied
  def test_eu_digital_goods_oss_applied
    skip "Scaffolding"
  end

  # Production-incident class: Seller crosses TX $100K economic nexus but never starts collecting
  def test_us_economic_nexus_tx_crossed_starts_collecting
    skip "Scaffolding"
  end

  # Production-incident class: Puerto Rico / Northern Cyprus / etc. mapped to wrong jurisdiction
  def test_special_jurisdiction_mapping_pr_treated_as_us_territory
    skip "Scaffolding"
  end

  # Production-incident class: DE buyer shown tax-exclusive price, sticker-shocked at checkout
  def test_locale_aware_inclusive_vs_exclusive_pricing_display
    skip "Scaffolding"
  end
end
