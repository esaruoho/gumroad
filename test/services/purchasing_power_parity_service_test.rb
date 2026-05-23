# frozen_string_literal: true

require "test_helper"

class PurchasingPowerParityServiceTest < ActiveSupport::TestCase
  setup do
    @namespace = Redis::Namespace.new(:ppp, redis: $redis)
    Compliance::Countries.mapping.keys.each { |k| @namespace.del(k) }
    @namespace.del("FAKE")
    @service = PurchasingPowerParityService.new
    @seller = users(:basic_user)
  end

  test "#get_factor produces no errors when country code is nil" do
    @namespace.set("FAKE", "0.9876543210")
    assert_equal 1, @service.get_factor(nil, @seller)
  end

  test "#get_factor returns the set factor when seller has no ppp limit" do
    @namespace.set("FAKE", "0.9876543210")
    assert_equal 0.9876543210, @service.get_factor("FAKE", @seller)
  end

  test "#get_factor returns the set factor when seller's minimum ppp factor is lower than the set factor" do
    @namespace.set("FAKE", "0.9876543210")
    @seller.stub(:min_ppp_factor, 0.6) do
      assert_equal 0.9876543210, @service.get_factor("FAKE", @seller)
    end
  end

  test "#get_factor returns the seller's minimum ppp factor when higher than the corresponding factor" do
    @namespace.set("FAKE", "0.9876543210")
    @seller.stub(:min_ppp_factor, 0.99) do
      assert_equal 0.99, @service.get_factor("FAKE", @seller)
    end
  end

  test "#set_factor sets the factor" do
    assert_equal 1, @service.get_factor("FAKE", @seller)
    assert_nil @namespace.get("FAKE")

    @service.set_factor("FAKE", 0.0123456789)

    assert_equal 0.0123456789, @service.get_factor("FAKE", @seller)
    assert_equal "0.0123456789", @namespace.get("FAKE")
  end

  test "#get_all_countries_factors returns a hash of factors for all countries" do
    @seller.update!(purchasing_power_parity_limit: 60)
    @namespace.set("FR", "0.123")
    @namespace.set("IT", "0.456")
    @namespace.set("GB", "0.6")
    result = @service.get_all_countries_factors(@seller)
    assert_equal Compliance::Countries.mapping.keys, result.keys
    assert(result.values.all? { |value| value.is_a?(Float) })
    assert_equal 0.4, result["FR"]
    assert_equal 0.456, result["IT"]
    assert_equal 0.6, result["GB"]
    assert_equal 1.0, result["PL"]
  end
end
