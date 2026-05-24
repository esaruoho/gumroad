# frozen_string_literal: true

require "test_helper"

class MvaValidationServiceTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @vatstack_response = {
      "id" => "5e5a894fa5807929777ad9c7",
      "active" => true,
      "valid" => true,
      "valid_format" => true,
      "vat_number" => "977074010",
      "country_code" => "NO",
      "query" => "977074010MVA",
      "type" => "no_vat"
    }
  end

  teardown { Rails.cache.clear }

  def stub_vatstack(response)
    HTTParty.stub(:post, ->(_url, **_opts) { response }) do
      yield
    end
  end

  test "returns true when valid mva is provided" do
    stub_vatstack(@vatstack_response) do
      assert_equal true, MvaValidationService.new("977074010MVA").process
    end
  end

  test "returns false when valid mva is provided, but government services are down" do
    stub_vatstack(@vatstack_response.merge("valid" => nil)) do
      assert_equal false, MvaValidationService.new("977074010MVA").process
    end
  end

  test "returns false when nil mva is provided" do
    assert_equal false, MvaValidationService.new(nil).process
  end

  test "returns false when blank mva is provided" do
    assert_equal false, MvaValidationService.new("   ").process
  end

  test "returns false when mva with invalid format is provided" do
    invalid_input_response = { "code" => "INVALID_INPUT", "query" => "SOMEINVALIDID", "valid" => false, "valid_format" => false }
    stub_vatstack(invalid_input_response) do
      assert_equal false, MvaValidationService.new("some-invalid-id").process
    end
  end

  test "returns false when invalid mva is provided" do
    stub_vatstack(@vatstack_response.merge("valid" => false)) do
      assert_equal false, MvaValidationService.new("11111111111").process
    end
  end

  test "returns false when inactive mva is provided" do
    stub_vatstack(@vatstack_response.merge("active" => false)) do
      assert_equal false, MvaValidationService.new("12345678901").process
    end
  end
end
