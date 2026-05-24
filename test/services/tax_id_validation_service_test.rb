# frozen_string_literal: true

require "test_helper"

class TaxIdValidationServiceTest < ActiveSupport::TestCase
  setup { Rails.cache.clear }
  teardown { Rails.cache.clear }

  TAX_ID = "528491"
  COUNTRY_CODE = "IS"

  test "returns true when a valid tax id is provided" do
    WebMock.stub_request(:get, "https://v3.api.taxid.pro/validate?country=#{COUNTRY_CODE}&tin=#{TAX_ID}")
      .to_return(status: 200, body: { "is_valid" => true }.to_json, headers: { "Content-Type" => "application/json" })
    assert_equal true, TaxIdValidationService.new(TAX_ID, COUNTRY_CODE).process
  end

  test "returns false when the tax id is nil" do
    assert_equal false, TaxIdValidationService.new(nil, COUNTRY_CODE).process
  end

  test "returns false when the tax id is empty" do
    assert_equal false, TaxIdValidationService.new("", COUNTRY_CODE).process
  end

  test "returns false when the country code is nil" do
    assert_equal false, TaxIdValidationService.new(TAX_ID, nil).process
  end

  test "returns false when the country code is empty" do
    assert_equal false, TaxIdValidationService.new(TAX_ID, "").process
  end

  test "returns false when the tax id is not valid" do
    WebMock.stub_request(:get, "https://v3.api.taxid.pro/validate?country=#{COUNTRY_CODE}&tin=1234567890")
      .to_return(status: 200, body: { "is_valid" => false }.to_json, headers: { "Content-Type" => "application/json" })
    assert_equal false, TaxIdValidationService.new("1234567890", COUNTRY_CODE).process
  end
end
