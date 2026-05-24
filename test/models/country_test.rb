# frozen_string_literal: true

require "test_helper"

class CountryTest < ActiveSupport::TestCase
  test "#supports_stripe_cross_border_payouts? returns true if country only supports cross-border payouts via stripe otherwise returns false" do
      assert_equal false, Country.new("US").supports_stripe_cross_border_payouts?
      assert_equal false, Country.new("GB").supports_stripe_cross_border_payouts?
      assert_equal false, Country.new("AU").supports_stripe_cross_border_payouts?
      assert_equal false, Country.new("FR").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("TH").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("KR").supports_stripe_cross_border_payouts?
      assert_equal false, Country.new("AE").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("ET").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("BN").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("GY").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("GT").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("IL").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("TT").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("PH").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("MX").supports_stripe_cross_border_payouts?
      assert_equal false, Country.new("SE").supports_stripe_cross_border_payouts?
      assert_equal false, Country.new("RO").supports_stripe_cross_border_payouts?
      assert_equal false, Country.new("NO").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("AR").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("PE").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("IN").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("TW").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("VN").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("NA").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("AG").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("TZ").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("ID").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("AL").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("JO").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("NG").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("AZ").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("BH").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("CR").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("CL").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("PK").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("BA").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("TR").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("BW").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("MA").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("RS").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("ZA").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("KE").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("EG").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("CO").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("AO").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("NE").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("SM").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("SA").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("KZ").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("EC").supports_stripe_cross_border_payouts?
      assert_equal false, Country.new("LI").supports_stripe_cross_border_payouts?
      assert_equal false, Country.new("JP").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("MY").supports_stripe_cross_border_payouts?
      assert_equal false, Country.new("GI").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("UY").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("RW").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("MU").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("JM").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("OM").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("DO").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("UZ").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("BO").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("TN").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("MD").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("PA").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("SV").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("BD").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("BT").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("LA").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("MZ").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("MG").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("PY").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("GH").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("AM").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("LK").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("KW").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("MK").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("IS").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("QA").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("BS").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("LC").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("SN").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("KH").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("MN").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("GA").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("MC").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("DZ").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("MO").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("BJ").supports_stripe_cross_border_payouts?
      assert_equal true, Country.new("CI").supports_stripe_cross_border_payouts?
  end

  test "#can_accept_stripe_charges? returns true if country supports payments via stripe otherwise returns false" do
      assert_equal true, Country.new("US").can_accept_stripe_charges?
      assert_equal true, Country.new("GB").can_accept_stripe_charges?
      assert_equal true, Country.new("AU").can_accept_stripe_charges?
      assert_equal true, Country.new("FR").can_accept_stripe_charges?
      assert_equal false, Country.new("TH").can_accept_stripe_charges?
      assert_equal false, Country.new("KR").can_accept_stripe_charges?
      assert_equal true, Country.new("AE").can_accept_stripe_charges?
      assert_equal false, Country.new("IL").can_accept_stripe_charges?
      assert_equal false, Country.new("TT").can_accept_stripe_charges?
      assert_equal false, Country.new("PH").can_accept_stripe_charges?
      assert_equal false, Country.new("MX").can_accept_stripe_charges?
      assert_equal true, Country.new("SE").can_accept_stripe_charges?
      assert_equal true, Country.new("RO").can_accept_stripe_charges?
      assert_equal true, Country.new("NO").can_accept_stripe_charges?
      assert_equal false, Country.new("AR").can_accept_stripe_charges?
      assert_equal false, Country.new("PE").can_accept_stripe_charges?
      assert_equal false, Country.new("NA").can_accept_stripe_charges?
      assert_equal false, Country.new("ET").can_accept_stripe_charges?
      assert_equal false, Country.new("BN").can_accept_stripe_charges?
      assert_equal false, Country.new("GY").can_accept_stripe_charges?
      assert_equal false, Country.new("GT").can_accept_stripe_charges?
      assert_equal false, Country.new("AG").can_accept_stripe_charges?
      assert_equal false, Country.new("TZ").can_accept_stripe_charges?
      assert_equal false, Country.new("IN").can_accept_stripe_charges?
      assert_equal false, Country.new("TW").can_accept_stripe_charges?
      assert_equal false, Country.new("AL").can_accept_stripe_charges?
      assert_equal false, Country.new("BH").can_accept_stripe_charges?
      assert_equal false, Country.new("RW").can_accept_stripe_charges?
      assert_equal false, Country.new("JO").can_accept_stripe_charges?
      assert_equal false, Country.new("NG").can_accept_stripe_charges?
      assert_equal false, Country.new("AZ").can_accept_stripe_charges?
      assert_equal false, Country.new("VN").can_accept_stripe_charges?
      assert_equal false, Country.new("ID").can_accept_stripe_charges?
      assert_equal false, Country.new("CR").can_accept_stripe_charges?
      assert_equal false, Country.new("BD").can_accept_stripe_charges?
      assert_equal false, Country.new("BT").can_accept_stripe_charges?
      assert_equal false, Country.new("LA").can_accept_stripe_charges?
      assert_equal false, Country.new("MZ").can_accept_stripe_charges?
      assert_equal false, Country.new("CL").can_accept_stripe_charges?
      assert_equal false, Country.new("BW").can_accept_stripe_charges?
      assert_equal false, Country.new("PK").can_accept_stripe_charges?
      assert_equal false, Country.new("TR").can_accept_stripe_charges?
      assert_equal true, Country.new("LI").can_accept_stripe_charges?
      assert_equal false, Country.new("BA").can_accept_stripe_charges?
      assert_equal false, Country.new("MA").can_accept_stripe_charges?
      assert_equal false, Country.new("RS").can_accept_stripe_charges?
      assert_equal false, Country.new("ZA").can_accept_stripe_charges?
      assert_equal false, Country.new("KE").can_accept_stripe_charges?
      assert_equal false, Country.new("EG").can_accept_stripe_charges?
      assert_equal false, Country.new("AO").can_accept_stripe_charges?
      assert_equal false, Country.new("NE").can_accept_stripe_charges?
      assert_equal false, Country.new("SM").can_accept_stripe_charges?
      assert_equal false, Country.new("CO").can_accept_stripe_charges?
      assert_equal false, Country.new("SA").can_accept_stripe_charges?
      assert_equal false, Country.new("KZ").can_accept_stripe_charges?
      assert_equal false, Country.new("EC").can_accept_stripe_charges?
      assert_equal true, Country.new("JP").can_accept_stripe_charges?
      assert_equal false, Country.new("MY").can_accept_stripe_charges?
      assert_equal true, Country.new("GI").can_accept_stripe_charges?
      assert_equal false, Country.new("UY").can_accept_stripe_charges?
      assert_equal false, Country.new("MU").can_accept_stripe_charges?
      assert_equal false, Country.new("JM").can_accept_stripe_charges?
      assert_equal false, Country.new("OM").can_accept_stripe_charges?
      assert_equal false, Country.new("DO").can_accept_stripe_charges?
      assert_equal false, Country.new("UZ").can_accept_stripe_charges?
      assert_equal false, Country.new("BO").can_accept_stripe_charges?
      assert_equal false, Country.new("TN").can_accept_stripe_charges?
      assert_equal false, Country.new("MD").can_accept_stripe_charges?
      assert_equal false, Country.new("PA").can_accept_stripe_charges?
      assert_equal false, Country.new("SV").can_accept_stripe_charges?
      assert_equal false, Country.new("MG").can_accept_stripe_charges?
      assert_equal false, Country.new("PY").can_accept_stripe_charges?
      assert_equal false, Country.new("GH").can_accept_stripe_charges?
      assert_equal false, Country.new("AM").can_accept_stripe_charges?
      assert_equal false, Country.new("LK").can_accept_stripe_charges?
      assert_equal false, Country.new("KW").can_accept_stripe_charges?
      assert_equal false, Country.new("MK").can_accept_stripe_charges?
      assert_equal false, Country.new("IS").can_accept_stripe_charges?
      assert_equal false, Country.new("QA").can_accept_stripe_charges?
      assert_equal false, Country.new("BS").can_accept_stripe_charges?
      assert_equal false, Country.new("LC").can_accept_stripe_charges?
      assert_equal false, Country.new("SN").can_accept_stripe_charges?
      assert_equal false, Country.new("KH").can_accept_stripe_charges?
      assert_equal false, Country.new("MN").can_accept_stripe_charges?
      assert_equal false, Country.new("GA").can_accept_stripe_charges?
      assert_equal false, Country.new("MC").can_accept_stripe_charges?
      assert_equal false, Country.new("DZ").can_accept_stripe_charges?
      assert_equal false, Country.new("MO").can_accept_stripe_charges?
      assert_equal false, Country.new("BJ").can_accept_stripe_charges?
      assert_equal false, Country.new("CI").can_accept_stripe_charges?
  end

  test "#stripe_capabilities returns country-specific stripe capabilities" do
      assert_equal StripeMerchantAccountManager::REQUESTED_CAPABILITIES, Country.new("US").stripe_capabilities
      assert_equal StripeMerchantAccountManager::REQUESTED_CAPABILITIES, Country.new("GB").stripe_capabilities
      assert_equal StripeMerchantAccountManager::REQUESTED_CAPABILITIES, Country.new("AU").stripe_capabilities
      assert_equal StripeMerchantAccountManager::REQUESTED_CAPABILITIES, Country.new("FR").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("TH").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("KR").stripe_capabilities
      assert_equal StripeMerchantAccountManager::REQUESTED_CAPABILITIES, Country.new("AE").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("IL").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("TT").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("PH").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("MX").stripe_capabilities
      assert_equal StripeMerchantAccountManager::REQUESTED_CAPABILITIES, Country.new("SE").stripe_capabilities
      assert_equal StripeMerchantAccountManager::REQUESTED_CAPABILITIES, Country.new("RO").stripe_capabilities
      assert_equal StripeMerchantAccountManager::REQUESTED_CAPABILITIES, Country.new("LI").stripe_capabilities
      assert_equal StripeMerchantAccountManager::REQUESTED_CAPABILITIES, Country.new("NO").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("BD").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("BT").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("LA").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("MZ").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("AR").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("PE").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("AL").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("BH").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("NA").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("AG").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("TZ").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("JO").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("ET").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("BN").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("GY").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("GT").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("NG").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("AZ").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("IN").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("TW").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("BA").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("VN").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("ID").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("CR").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("CL").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("PK").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("TR").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("MA").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("RS").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("ZA").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("KE").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("EG").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("CO").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("AO").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("NE").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("SM").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("SA").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("KZ").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("EC").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("BW").stripe_capabilities
      assert_equal StripeMerchantAccountManager::REQUESTED_CAPABILITIES, Country.new("JP").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("MY").stripe_capabilities
      assert_equal StripeMerchantAccountManager::REQUESTED_CAPABILITIES, Country.new("GI").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("UY").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("MU").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("JM").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("OM").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("RW").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("DO").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("UZ").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("BO").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("TN").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("MD").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("PA").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("SV").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("MG").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("PY").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("GH").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("AM").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("LK").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("KW").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("MK").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("IS").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("QA").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("BS").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("LC").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("SN").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("KH").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("MN").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("GA").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("MC").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("DZ").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("MO").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("BJ").stripe_capabilities
      assert_equal StripeMerchantAccountManager::CROSS_BORDER_PAYOUTS_ONLY_CAPABILITIES, Country.new("CI").stripe_capabilities
  end

  test "#stripe_country_code maps US territory ISO codes to their parent country code expected by Stripe" do
      assert_equal "US", Country.new("PR").stripe_country_code
  end

  test "#stripe_country_code passes through every other country code unchanged" do
      assert_equal "US", Country.new("US").stripe_country_code
      assert_equal "GB", Country.new("GB").stripe_country_code
      assert_equal "JP", Country.new("JP").stripe_country_code
      assert_equal "VN", Country.new("VN").stripe_country_code
  end

  test "#default_currency returns the currency which is set as default currency for all the accounts from the country" do
      assert_equal Currency::USD, Country.new("US").default_currency
      assert_equal Currency::USD, Country.new("PR").default_currency
      assert_equal Currency::GBP, Country.new("GB").default_currency
      assert_equal Currency::AUD, Country.new("AU").default_currency
      assert_equal Currency::EUR, Country.new("FR").default_currency
      assert_nil Country.new("TH").default_currency
      assert_nil Country.new("KR").default_currency
      assert_nil Country.new("AE").default_currency
      assert_nil Country.new("IL").default_currency
      assert_nil Country.new("TT").default_currency
      assert_nil Country.new("ET").default_currency
      assert_nil Country.new("BN").default_currency
      assert_nil Country.new("GY").default_currency
      assert_nil Country.new("GT").default_currency
      assert_nil Country.new("PH").default_currency
      assert_nil Country.new("NA").default_currency
      assert_nil Country.new("AG").default_currency
      assert_nil Country.new("TZ").default_currency
      assert_nil Country.new("MX").default_currency
      assert_nil Country.new("SE").default_currency
      assert_nil Country.new("RO").default_currency
      assert_nil Country.new("AR").default_currency
      assert_nil Country.new("PE").default_currency
      assert_nil Country.new("NO").default_currency
      assert_nil Country.new("IN").default_currency
      assert_nil Country.new("TW").default_currency
      assert_nil Country.new("VN").default_currency
      assert_nil Country.new("BD").default_currency
      assert_nil Country.new("BT").default_currency
      assert_nil Country.new("LA").default_currency
      assert_nil Country.new("MZ").default_currency
      assert_equal Currency::CHF, Country.new("LI").default_currency
      assert_nil Country.new("ID").default_currency
      assert_nil Country.new("CR").default_currency
      assert_nil Country.new("CL").default_currency
      assert_nil Country.new("PK").default_currency
      assert_nil Country.new("AO").default_currency
      assert_nil Country.new("NE").default_currency
      assert_nil Country.new("SM").default_currency
      assert_nil Country.new("BA").default_currency
      assert_nil Country.new("TR").default_currency
      assert_nil Country.new("MA").default_currency
      assert_nil Country.new("RS").default_currency
      assert_nil Country.new("ZA").default_currency
      assert_nil Country.new("KE").default_currency
      assert_nil Country.new("EG").default_currency
      assert_nil Country.new("CO").default_currency
      assert_nil Country.new("SA").default_currency
      assert_nil Country.new("BW").default_currency
      assert_nil Country.new("KZ").default_currency
      assert_nil Country.new("EC").default_currency
      assert_equal Currency::JPY, Country.new("JP").default_currency
      assert_nil Country.new("MY").default_currency
      assert_nil Country.new("GI").default_currency
      assert_nil Country.new("UY").default_currency
      assert_nil Country.new("MU").default_currency
      assert_nil Country.new("JM").default_currency
      assert_nil Country.new("OM").default_currency
      assert_nil Country.new("DO").default_currency
      assert_nil Country.new("UZ").default_currency
      assert_nil Country.new("BO").default_currency
      assert_nil Country.new("TN").default_currency
      assert_nil Country.new("RW").default_currency
      assert_nil Country.new("AL").default_currency
      assert_nil Country.new("AZ").default_currency
      assert_nil Country.new("BH").default_currency
      assert_nil Country.new("NG").default_currency
      assert_nil Country.new("JO").default_currency
      assert_nil Country.new("MD").default_currency
      assert_nil Country.new("PA").default_currency
      assert_nil Country.new("SV").default_currency
      assert_nil Country.new("MG").default_currency
      assert_nil Country.new("PY").default_currency
      assert_nil Country.new("GH").default_currency
      assert_nil Country.new("AM").default_currency
      assert_nil Country.new("LK").default_currency
      assert_nil Country.new("KW").default_currency
      assert_nil Country.new("MK").default_currency
      assert_nil Country.new("IS").default_currency
      assert_nil Country.new("QA").default_currency
      assert_nil Country.new("BS").default_currency
      assert_nil Country.new("LC").default_currency
      assert_nil Country.new("SN").default_currency
      assert_nil Country.new("KH").default_currency
      assert_nil Country.new("MN").default_currency
      assert_nil Country.new("GA").default_currency
      assert_nil Country.new("MC").default_currency
      assert_nil Country.new("DZ").default_currency
      assert_nil Country.new("MO").default_currency
      assert_nil Country.new("BJ").default_currency
      assert_nil Country.new("CI").default_currency
      assert_nil Country.new("BG").default_currency
  end

  test "#payout_currency returns the currency which is used for sending stripe payouts to the country" do
      assert_equal Currency::USD, Country.new("US").payout_currency
      assert_equal Currency::USD, Country.new("PR").payout_currency
      assert_equal Currency::GBP, Country.new("GB").payout_currency
      assert_equal Currency::AUD, Country.new("AU").payout_currency
      assert_equal Currency::EUR, Country.new("FR").payout_currency
      assert_equal Currency::THB, Country.new("TH").payout_currency
      assert_equal Currency::KRW, Country.new("KR").payout_currency
      assert_equal Currency::AED, Country.new("AE").payout_currency
      assert_equal Currency::ILS, Country.new("IL").payout_currency
      assert_equal Currency::TTD, Country.new("TT").payout_currency
      assert_equal Currency::PHP, Country.new("PH").payout_currency
      assert_equal Currency::ALL, Country.new("AL").payout_currency
      assert_equal Currency::JOD, Country.new("JO").payout_currency
      assert_equal Currency::AZN, Country.new("AZ").payout_currency
      assert_equal Currency::BHD, Country.new("BH").payout_currency
      assert_equal Currency::ETB, Country.new("ET").payout_currency
      assert_equal Currency::BND, Country.new("BN").payout_currency
      assert_equal Currency::GYD, Country.new("GY").payout_currency
      assert_equal Currency::GTQ, Country.new("GT").payout_currency
      assert_equal Currency::NGN, Country.new("NG").payout_currency
      assert_equal Currency::MXN, Country.new("MX").payout_currency
      assert_equal Currency::SEK, Country.new("SE").payout_currency
      assert_equal Currency::NAD, Country.new("NA").payout_currency
      assert_equal Currency::XCD, Country.new("AG").payout_currency
      assert_equal Currency::TZS, Country.new("TZ").payout_currency
      assert_equal Currency::RON, Country.new("RO").payout_currency
      assert_equal Currency::NOK, Country.new("NO").payout_currency
      assert_equal Currency::ARS, Country.new("AR").payout_currency
      assert_equal Currency::PEN, Country.new("PE").payout_currency
      assert_equal Currency::INR, Country.new("IN").payout_currency
      assert_equal Currency::CHF, Country.new("LI").payout_currency
      assert_equal Currency::TWD, Country.new("TW").payout_currency
      assert_equal Currency::VND, Country.new("VN").payout_currency
      assert_equal Currency::IDR, Country.new("ID").payout_currency
      assert_equal Currency::CRC, Country.new("CR").payout_currency
      assert_equal Currency::CLP, Country.new("CL").payout_currency
      assert_equal Currency::PKR, Country.new("PK").payout_currency
      assert_equal Currency::TRY, Country.new("TR").payout_currency
      assert_equal Currency::MAD, Country.new("MA").payout_currency
      assert_equal Currency::BAM, Country.new("BA").payout_currency
      assert_equal Currency::RSD, Country.new("RS").payout_currency
      assert_equal Currency::ZAR, Country.new("ZA").payout_currency
      assert_equal Currency::KES, Country.new("KE").payout_currency
      assert_equal Currency::RWF, Country.new("RW").payout_currency
      assert_equal Currency::EGP, Country.new("EG").payout_currency
      assert_equal Currency::BDT, Country.new("BD").payout_currency
      assert_equal Currency::BTN, Country.new("BT").payout_currency
      assert_equal Currency::LAK, Country.new("LA").payout_currency
      assert_equal Currency::MZN, Country.new("MZ").payout_currency
      assert_equal Currency::COP, Country.new("CO").payout_currency
      assert_equal Currency::BWP, Country.new("BW").payout_currency
      assert_equal Currency::SAR, Country.new("SA").payout_currency
      assert_equal Currency::JPY, Country.new("JP").payout_currency
      assert_equal Currency::KZT, Country.new("KZ").payout_currency
      assert_equal Currency::USD, Country.new("EC").payout_currency
      assert_equal Currency::MYR, Country.new("MY").payout_currency
      assert_equal Currency::UYU, Country.new("UY").payout_currency
      assert_equal Currency::MUR, Country.new("MU").payout_currency
      assert_equal Currency::JMD, Country.new("JM").payout_currency
      assert_equal Currency::DOP, Country.new("DO").payout_currency
      assert_equal Currency::UZS, Country.new("UZ").payout_currency
      assert_equal Currency::BOB, Country.new("BO").payout_currency
      assert_equal Currency::MDL, Country.new("MD").payout_currency
      assert_equal Currency::USD, Country.new("PA").payout_currency
      assert_equal Currency::USD, Country.new("SV").payout_currency
      assert_equal Currency::GBP, Country.new("GI").payout_currency
      assert_equal Currency::OMR, Country.new("OM").payout_currency
      assert_equal Currency::AOA, Country.new("AO").payout_currency
      assert_equal Currency::XOF, Country.new("NE").payout_currency
      assert_equal Currency::EUR, Country.new("SM").payout_currency
      assert_equal Currency::TND, Country.new("TN").payout_currency
      assert_equal Currency::MGA, Country.new("MG").payout_currency
      assert_equal Currency::PYG, Country.new("PY").payout_currency
      assert_equal Currency::GHS, Country.new("GH").payout_currency
      assert_equal Currency::AMD, Country.new("AM").payout_currency
      assert_equal Currency::LKR, Country.new("LK").payout_currency
      assert_equal Currency::KWD, Country.new("KW").payout_currency
      assert_equal Currency::MKD, Country.new("MK").payout_currency
      assert_equal Currency::EUR, Country.new("IS").payout_currency
      assert_equal Currency::QAR, Country.new("QA").payout_currency
      assert_equal Currency::BSD, Country.new("BS").payout_currency
      assert_equal Currency::XCD, Country.new("LC").payout_currency
      assert_equal Currency::XOF, Country.new("SN").payout_currency
      assert_equal Currency::KHR, Country.new("KH").payout_currency
      assert_equal Currency::MNT, Country.new("MN").payout_currency
      assert_equal Currency::XAF, Country.new("GA").payout_currency
      assert_equal Currency::EUR, Country.new("MC").payout_currency
      assert_equal Currency::DZD, Country.new("DZ").payout_currency
      assert_equal Currency::MOP, Country.new("MO").payout_currency
      assert_equal Currency::XOF, Country.new("BJ").payout_currency
      assert_equal Currency::XOF, Country.new("CI").payout_currency
      assert_equal Currency::EUR, Country.new("BG").payout_currency
  end

  test "#min_cross_border_payout_amount_local_cents returns a minimum payout amount cents in local currency for all supported cross-border countries" do
      Country.const_get(:CROSS_BORDER_PAYOUTS_COUNTRIES).each do |country|
        assert_not_nil Country.new(country.alpha2).min_cross_border_payout_amount_local_cents
      end
  end

  test "#min_cross_border_payout_amount_local_cents returns the correct minimum payout amount in local currency cents for supported cross-border countries" do
      assert_equal 600_00, Country.new("TH").min_cross_border_payout_amount_local_cents
      assert_equal 40_000_00, Country.new("KR").min_cross_border_payout_amount_local_cents
      assert_equal 550_00, Country.new("NA").min_cross_border_payout_amount_local_cents
      assert_equal 20_00, Country.new("PH").min_cross_border_payout_amount_local_cents
      assert_equal 10_00, Country.new("MX").min_cross_border_payout_amount_local_cents
      assert_equal 200_00, Country.new("BO").min_cross_border_payout_amount_local_cents
      assert_equal 343_000_00, Country.new("UZ").min_cross_border_payout_amount_local_cents
      assert_equal 6_300_00, Country.new("GY").min_cross_border_payout_amount_local_cents
      assert_equal 123_000_00, Country.new("KH").min_cross_border_payout_amount_local_cents
      assert_equal 105_000_00, Country.new("MN").min_cross_border_payout_amount_local_cents
      assert_equal 23_000_00, Country.new("AO").min_cross_border_payout_amount_local_cents
      assert_equal 4_600_00, Country.new("AR").min_cross_border_payout_amount_local_cents
      assert_equal 100_00, Country.new("RW").min_cross_border_payout_amount_local_cents
      assert_equal 800_00, Country.new("TW").min_cross_border_payout_amount_local_cents
      assert_equal 12_100_00, Country.new("AM").min_cross_border_payout_amount_local_cents
      assert_equal 2_500_00, Country.new("BT").min_cross_border_payout_amount_local_cents
      assert_equal 516_000_00, Country.new("LA").min_cross_border_payout_amount_local_cents
      assert_equal 1_700_00, Country.new("MZ").min_cross_border_payout_amount_local_cents
      assert_equal 23_000_00, Country.new("CL").min_cross_border_payout_amount_local_cents
      assert_equal 1_00, Country.new("OM").min_cross_border_payout_amount_local_cents
      assert_equal 3_000_00, Country.new("AL").min_cross_border_payout_amount_local_cents
      assert_equal 50_00, Country.new("AZ").min_cross_border_payout_amount_local_cents
      assert_equal 210_000_00, Country.new("PY").min_cross_border_payout_amount_local_cents
      assert_equal 100_00, Country.new("GA").min_cross_border_payout_amount_local_cents
      assert_equal 1_00, Country.new("DZ").min_cross_border_payout_amount_local_cents
  end

  test "#min_cross_border_payout_amount_local_cents returns nil for regular (non cross-border) payout and unsupported countries" do
      regular_payout_countries = User::Compliance.const_get(:SUPPORTED_COUNTRIES) - Country.const_get(:CROSS_BORDER_PAYOUTS_COUNTRIES)
      regular_payout_countries.each do |country|
        assert_nil Country.new(country.alpha2).min_cross_border_payout_amount_local_cents
      end
      assert_nil Country.new(Compliance::Countries::BRA.alpha2).min_cross_border_payout_amount_local_cents
  end

  test "#min_cross_border_payout_amount_usd_cents returns the min_cross_border_payout_amount_local_cents converted to usd cents" do
      Country.const_get(:CROSS_BORDER_PAYOUTS_COUNTRIES).map(&:alpha2).each do |country_alpha2_code|
        country = Country.new(country_alpha2_code)
        assert country.min_cross_border_payout_amount_usd_cents.present?
        assert_equal country.get_usd_cents(country.payout_currency, country.min_cross_border_payout_amount_local_cents), country.min_cross_border_payout_amount_usd_cents
      end
  end

  test "#min_cross_border_payout_amount_usd_cents returns 0 if min_cross_border_payout_amount_local_cents is nil" do
      regular_payout_countries = User::Compliance.const_get(:SUPPORTED_COUNTRIES) - Country.const_get(:CROSS_BORDER_PAYOUTS_COUNTRIES)
      regular_payout_countries.each do |country|
        assert_equal 0, Country.new(country.alpha2).min_cross_border_payout_amount_usd_cents
      end
      assert_equal 0, Country.new(Compliance::Countries::BRA.alpha2).min_cross_border_payout_amount_usd_cents
  end

end
