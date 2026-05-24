# frozen_string_literal: true

require "test_helper"

class BuildTaxRateCacheWorkerTest < ActiveSupport::TestCase
  def zip_tax_rate_attrs(overrides = {})
    {
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
    }.merge(overrides)
  end

  test "caches the maximum tax rate per state to be used in the product edit flow" do
    ZipTaxRate.create!(zip_tax_rate_attrs(combined_rate: 0.09, state: "CA"))
    ZipTaxRate.create!(zip_tax_rate_attrs(combined_rate: 0.095, state: "CA"))
    ZipTaxRate.create!(zip_tax_rate_attrs(combined_rate: 0.1, state: "CA"))
    ZipTaxRate.create!(zip_tax_rate_attrs(combined_rate: 0.08, state: "TX"))

    # Show it does not fail for nil states (VAT rates)
    ZipTaxRate.create!(zip_tax_rate_attrs(combined_rate: 0.08, state: nil, zip_code: nil, country: "DE"))
    ZipTaxRate.create!(zip_tax_rate_attrs(combined_rate: 0.08, state: nil, zip_code: nil, country: "GB"))

    BuildTaxRateCacheWorker.new.perform

    assert_nil ZipTaxRate.where(state: "WA").first

    us_tax_cache_namespace = Redis::Namespace.new(:max_tax_rate_per_state_cache_us, redis: $redis)
    assert_equal "0.1", us_tax_cache_namespace.get("US_CA")
    assert_equal "0.08", us_tax_cache_namespace.get("US_TX")
    assert_nil us_tax_cache_namespace.get("US_WA")
  end
end
