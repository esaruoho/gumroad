# frozen_string_literal: true

require "test_helper"

class AbnValidationServiceTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @vatstack_response = {
      "active" => true,
      "company_address" => "NSW 2020",
      "company_name" => "KANGAROO AIRWAYS LIMITED",
      "company_type" => "PUB",
      "consultation_number" => nil,
      "country_code" => "AU",
      "created" => "2022-02-13T16:09:08.189Z",
      "external_id" => nil,
      "id" => "62092d24a1f0d913207815ce",
      "query" => "51824753556",
      "requested" => "2022-02-13T16:09:08.186Z",
      "type" => "au_gst",
      "updated" => "2022-02-13T16:09:08.189Z",
      "valid" => true,
      "valid_format" => true,
      "vat_number" => "51824753556"
    }
  end

  def stub_httparty(query, response)
    captured = []
    orig = HTTParty.method(:post)
    HTTParty.define_singleton_method(:post) do |url, **opts|
      captured << [url, opts]
      response
    end
    yield captured
  ensure
    HTTParty.define_singleton_method(:post, orig)
  end

  test "returns true when valid abn is provided" do
    abn_id = "51824753556"
    stub_httparty(abn_id, @vatstack_response) do |captured|
      assert_equal true, AbnValidationService.new(abn_id).process
      assert_equal "https://api.vatstack.com/v1/validations", captured.first[0]
      assert_equal({ "type" => "au_gst", "query" => abn_id }, captured.first[1][:body])
      assert captured.first[1][:headers].key?("X-API-KEY")
    end
  end

  test "returns false when government services are down" do
    stub_httparty("51824753556", @vatstack_response.merge("valid" => nil)) do
      assert_equal false, AbnValidationService.new("51824753556").process
    end
  end

  test "returns false when nil abn is provided" do
    assert_equal false, AbnValidationService.new(nil).process
  end

  test "returns false when blank abn is provided" do
    assert_equal false, AbnValidationService.new("   ").process
  end

  test "returns false when abn with invalid format is provided" do
    invalid_input_response = {
      "code" => "INVALID_INPUT",
      "query" => "SOMEINVALIDID",
      "valid" => false,
      "valid_format" => false
    }
    stub_httparty("some-invalid-id", invalid_input_response) do
      assert_equal false, AbnValidationService.new("some-invalid-id").process
    end
  end

  test "returns false when invalid abn is provided" do
    stub_httparty("11111111111", @vatstack_response.merge("valid" => false)) do
      assert_equal false, AbnValidationService.new("11111111111").process
    end
  end

  test "returns false when inactive abn is provided" do
    stub_httparty("12345678901", @vatstack_response.merge("active" => false)) do
      assert_equal false, AbnValidationService.new("12345678901").process
    end
  end
end
