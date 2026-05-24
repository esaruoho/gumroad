require "test_helper"

class ZipTaxRateTest < ActiveSupport::TestCase
  def build(**attrs)
    ZipTaxRate.new({
      combined_rate: "0.1100000",
      county_rate: "0.0100000",
      special_rate: "0.0300000",
      state_rate: "0.0500000",
      city_rate: "0.0200000",
      state: "NY",
      zip_code: "10087",
      country: "US",
      is_seller_responsible: 1,
      is_epublication_rate: 0,
    }.merge(attrs))
  end

  test "requires a combined rate" do
    ztr = ZipTaxRate.new(zip_code: "90210", country: "US", state: "CA", is_seller_responsible: true)
    assert_not ztr.valid?
  end

  test "has `is_seller_responsible` flag" do
    flag_on = build(country: "GB", combined_rate: 0.1, is_seller_responsible: true, state: nil, zip_code: nil)
    flag_on.save!
    flag_off = build(country: "IT", combined_rate: 0.22, is_seller_responsible: false, state: nil, zip_code: nil)
    flag_off.save!

    assert_equal true, flag_on.is_seller_responsible
    assert_equal false, flag_off.is_seller_responsible
  end

  test "has `is_epublication_rate` flag" do
    flag_on = build(country: "AT", combined_rate: 0.1, is_epublication_rate: true, state: nil, zip_code: nil)
    flag_on.save!
    flag_off = build(country: "AT", combined_rate: 0.2, is_epublication_rate: false, state: nil, zip_code: nil)
    flag_off.save!

    assert_equal true, flag_on.is_epublication_rate
    assert_equal false, flag_off.is_epublication_rate
  end

  test "supports applicable years" do
    ztr = build(country: "SG", state: nil, zip_code: nil, combined_rate: 0.08, is_seller_responsible: false, applicable_years: [2023])
    ztr.save!

    assert_equal [2023], ztr.applicable_years
  end
end
