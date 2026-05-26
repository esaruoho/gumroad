# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../system_test_case"
require_relative "../checkout_page"
require_relative "../stripe_test_cards"

# Cross-border (buyer ≠ seller country) edge cases.
#
# Each test pins one (seller_country, buyer_country, card_country) triple and
# asserts charge currency, tax application, and country-specific rules. These
# scenarios produce production incidents disproportionately — a single
# regression here means real money flows wrong direction across a national
# border.
#
# See docs/checkout-edge-cases.md §1 for the matrix.
class CrossBorderTest < SystemTests::SystemTestCase
  def setup
    super
    @cp = CheckoutPage.new(@page)
  end

  # ===== US seller, EU buyer =====

  # Production-incident class: EU buyer charged in USD, VAT applied at wrong rate
  def test_us_seller_de_buyer_charged_in_eur_with_vat
    skip "Scaffolding — body filled in foundation pass + Codex"
  end

  # Production-incident class: GBP-denominated checkout still showing USD
  def test_us_seller_gb_buyer_charged_in_gbp_post_brexit_vat
    skip "Scaffolding"
  end

  # Production-incident class: JPY displayed with two decimals (¥1500.00 instead of ¥1500)
  def test_us_seller_jp_buyer_jpy_zero_decimal_display
    skip "Scaffolding"
  end

  # Production-incident class: Indian buyer missing RBI mandate, recurring fails
  def test_us_seller_in_buyer_rbi_sca_mandate_stored
    skip "Scaffolding"
  end

  # Production-incident class: BRL price displayed but PIX unavailable, buyer abandons
  def test_us_seller_br_buyer_pix_offered_when_seller_enabled
    skip "Scaffolding"
  end

  # ===== EU seller, US buyer (reverse direction) =====

  # Production-incident class: US buyer charged EU VAT they should never see
  def test_de_seller_us_buyer_no_vat_on_us_destination
    skip "Scaffolding"
  end

  # Production-incident class: EU intra-community VAT charged twice
  def test_de_seller_fr_buyer_eu_intra_community_vat
    skip "Scaffolding"
  end

  # Production-incident class: Post-Brexit GB seller still using EU OSS plumbing
  def test_gb_seller_us_buyer_no_eu_oss_post_brexit
    skip "Scaffolding"
  end

  # ===== Tax wrinkles by destination =====

  # Production-incident class: AUD-converted price missing GST
  def test_us_seller_au_buyer_gst_on_audconverted_price
    skip "Scaffolding"
  end

  # Production-incident class: Provincial sales tax (ON HST) not applied
  def test_us_seller_ca_buyer_on_hst_applied
    skip "Scaffolding"
  end

  # ===== Card-country ≠ buyer-country =====

  # Production-incident class: Tax follows card country instead of IP, EU expat in MX taxed wrong
  def test_us_seller_us_card_mx_ip_tax_follows_ip
    skip "Scaffolding"
  end

  # Production-incident class: Buyer spoofs EU billing address with US card, no anti-fraud signal
  def test_us_seller_us_card_de_billing_logs_mismatch_for_fraud_review
    skip "Scaffolding"
  end
end
