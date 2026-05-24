# frozen_string_literal: true

require "test_helper"

class GstValidationServiceTest < ActiveSupport::TestCase
  setup { Rails.cache.clear }
  teardown { Rails.cache.clear }

  ENDPOINT = "https://apisandbox.iras.gov.sg/iras/sb/GSTListing/SearchGSTRegistered"

  def stub_iras(gst_id, response)
    HTTParty.stub(:post, ->(url, **opts) {
      assert_equal ENDPOINT, url
      assert_equal 5, opts[:timeout]
      assert_equal "{\"clientID\":\"#{IRAS_API_ID}\",\"regID\":\"#{gst_id}\"}", opts[:body]
      assert_includes opts[:headers].keys, "X-IBM-Client-Secret"
      response
    }) do
      yield
    end
  end

  test "returns true when a valid gst id is provided" do
    gst_id = "T9100001B"
    success_response = {
      "returnCode" => "10",
      "data" => { "gstRegistrationNumber" => "T9100001B", "name" => "GUMROAD, INC.", "RegisteredFrom" => "2020-01-01T00:00:00", "Status" => "Registered", "Remarks" => "" },
      "info" => { "fieldInfoList" => [] }
    }
    stub_iras(gst_id, success_response) do
      assert_equal true, GstValidationService.new(gst_id).process
    end
  end

  test "returns false when nil gst id is provided" do
    assert_equal false, GstValidationService.new(nil).process
  end

  test "returns false when a blank gst id is provided" do
    assert_equal false, GstValidationService.new("   ").process
  end

  test "returns false when a valid gst id is provided, but IRAS returns a 500" do
    gst_id = "T9100001B"
    response = { "httpCode" => "500", "httpMessage" => "Internal Server Error", "moreInformation" => "" }
    stub_iras(gst_id, response) do
      assert_equal false, GstValidationService.new(gst_id).process
    end
  end

  test "returns false when IRAS cannot find a match for the provided gst id" do
    gst_id = "M90379350P"
    response = { "returnCode " => "20", "info" => { "fieldInfoList" => [], "message" => "No match data found", "messageCode" => "400033" } }
    stub_iras(gst_id, response) do
      assert_equal false, GstValidationService.new(gst_id).process
    end
  end

  test "returns false when a gst id is provided with an invalid format" do
    gst_id = "asdf"
    response = {
      "returnCode" => "30",
      "info" => { "fieldInfoList" => [{ "field" => "regId", "message" => "Value is not valid" }], "message" => "Arguments Error", "messageCode" => "850301" }
    }
    stub_iras(gst_id, response) do
      assert_equal false, GstValidationService.new(gst_id).process
    end
  end
end
