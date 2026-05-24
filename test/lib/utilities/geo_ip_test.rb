# frozen_string_literal: true

require "test_helper"

class GeoIpTest < ActiveSupport::TestCase
  # Build a fake MaxMind::GeoIP2::Reader-like object. The GEOIP constant in
  # the real app is a MaxMind reader; in tests the mmdb file isn't shipped,
  # so we substitute a stub via `with_const`.
  def fake_geoip(city_result: nil, raise_for: nil)
    stub = Object.new
    stub.define_singleton_method(:city) do |ip|
      raise raise_for if raise_for && raise_for.include?(ip)
      city_result
    end
    stub
  end

  # Build a city-shaped struct: country/most_specific_subdivision/city/postal/location
  # each respond to the attribute readers GeoIp.lookup hits.
  def city_double(country_name:, country_code:, region_code:, city_name:, postal_code:, latitude:, longitude:)
    country = Struct.new(:name, :iso_code).new(country_name, country_code)
    subdivision = Struct.new(:iso_code).new(region_code)
    city = Struct.new(:name).new(city_name)
    postal = Struct.new(:code).new(postal_code)
    location = Struct.new(:latitude, :longitude).new(latitude, longitude)
    obj = Object.new
    obj.define_singleton_method(:country) { country }
    obj.define_singleton_method(:most_specific_subdivision) { subdivision }
    obj.define_singleton_method(:city) { city }
    obj.define_singleton_method(:postal) { postal }
    obj.define_singleton_method(:location) { location }
    obj
  end

  test "returns nil when the IP cannot be matched to a location" do
    # MaxMind raises MaxMind::GeoIP2::AddressNotFoundError for unrouted IPs;
    # GeoIp.lookup rescues to nil.
    geoip = fake_geoip(raise_for: ["127.0.0.1"])
    with_const(:GEOIP, geoip) do
      assert_nil GeoIp.lookup("127.0.0.1")
    end
  end

  test "returns a populated Result for a US IPv4 match" do
    city = city_double(
      country_name: "United States", country_code: "US",
      region_code: "CA", city_name: "San Francisco",
      postal_code: "94110", latitude: nil, longitude: nil
    )
    with_const(:GEOIP, fake_geoip(city_result: city)) do
      result = GeoIp.lookup("104.193.168.19")
      assert_equal "United States", result.country_name
      assert_equal "US", result.country_code
      assert_equal "CA", result.region_name
      assert_equal "San Francisco", result.city_name
      assert_equal "94110", result.postal_code
      assert_nil result.latitude
      assert_nil result.longitude
    end
  end

  test "returns a populated Result for an IPv6 match" do
    city = city_double(
      country_name: "France", country_code: "FR",
      region_code: nil, city_name: "Belfort",
      postal_code: "90000", latitude: nil, longitude: nil
    )
    with_const(:GEOIP, fake_geoip(city_result: city)) do
      result = GeoIp.lookup("2001:861:5bc0:cb60:500d:3535:e6a7:62a0")
      assert_equal "France", result.country_name
      assert_equal "FR", result.country_code
      assert_equal "Belfort", result.city_name
      assert_equal "90000", result.postal_code
      assert_nil result.latitude
      assert_nil result.longitude
    end
  end

  test "sanitizes invalid UTF-8 bytes in the underlying MaxMind result" do
    city = city_double(
      country_name: "Unit\xB7ed States", country_code: "U\xB7S",
      region_code: "C\xB7A", city_name: "San F\xB7rancisco",
      postal_code: "941\xB703", latitude: "103\xB7103", longitude: "103\xB7103"
    )
    with_const(:GEOIP, fake_geoip(city_result: city)) do
      result = GeoIp.lookup("104.193.168.19")
      assert_equal "Unit?ed States", result.country_name
      assert_equal "U?S", result.country_code
      assert_equal "C?A", result.region_name
      assert_equal "San F?rancisco", result.city_name
      assert_equal "941?03", result.postal_code
      assert_equal "103?103", result.latitude
      assert_equal "103?103", result.longitude
    end
  end
end
