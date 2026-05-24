# frozen_string_literal: true

require "test_helper"

class Exports::TaxSummary::AnnualTest < ActiveSupport::TestCase
  test "initializer captures year and optional batch bounds" do
    annual = Exports::TaxSummary::Annual.new(year: 2024, start: 100, finish: 999)

    assert_equal 2024, annual.instance_variable_get(:@year)
    assert_equal 100, annual.instance_variable_get(:@start)
    assert_equal 999, annual.instance_variable_get(:@finish)
  end

  test "initializer defaults start and finish to nil so find_each scans all users" do
    annual = Exports::TaxSummary::Annual.new(year: 2023)

    assert_nil annual.instance_variable_get(:@start)
    assert_nil annual.instance_variable_get(:@finish)
  end

  test "#tempfile_name embeds the year, a UUID, and the ISO week" do
    annual = Exports::TaxSummary::Annual.new(year: 2024)
    name = annual.send(:tempfile_name)

    assert_match(/\Aannual_exports_2024_[0-9a-f-]+-\d{2}\.csv\z/, name)
  end

  # TODO: full #perform exercises Exports::TaxSummary::Payable (which hits
  # PaymentsHelper#create_payment_with_purchase to seed 12 payments across 12
  # months), encrypted/strongbox fields on UserComplianceInfo, and uploads
  # the CSV to S3 via ExpiringS3FileService. VCR-tagged. Out of scope for the
  # fixture-only Minitest lane. Original:
  # spec/services/exports/tax_summary/annual_spec.rb
end
