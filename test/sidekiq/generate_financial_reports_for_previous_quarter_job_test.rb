# frozen_string_literal: true

require "test_helper"

class GenerateFinancialReportsForPreviousQuarterJobTest < ActiveSupport::TestCase
  setup do
    CreateVatReportJob.clear
    GenerateSalesReportJob.clear
  end

  test "does not generate any reports when the Rails environment is not production" do
    GenerateFinancialReportsForPreviousQuarterJob.new.perform

    assert_equal 0, CreateVatReportJob.jobs.size
    assert_equal 0, GenerateSalesReportJob.jobs.size
  end

  test "generates reports when the Rails environment is production" do
    Rails.env.stub(:production?, true) do
      GenerateFinancialReportsForPreviousQuarterJob.new.perform
    end

    vat_args = CreateVatReportJob.jobs.last["args"]
    assert_kind_of Integer, vat_args[0]
    assert_kind_of Integer, vat_args[1]

    countries = GenerateSalesReportJob.jobs.map { |j| j["args"][0] }
    assert_includes countries, "GB"
    assert_includes countries, "AU"
    assert_includes countries, "SG"
    assert_includes countries, "NO"

    GenerateSalesReportJob.jobs.each do |job|
      args = job["args"]
      assert_kind_of String, args[1]
      assert_kind_of String, args[2]
      assert_equal GenerateSalesReportJob::ALL_SALES, args[3]
    end
  end

  [[2017,  1, 2016, 4],
   [2017,  2, 2016, 4],
   [2017,  3, 2016, 4],
   [2017,  4, 2017, 1],
   [2017,  5, 2017, 1],
   [2017,  6, 2017, 1],
   [2017,  7, 2017, 2],
   [2017, 10, 2017, 3]].each do |current_year, current_month, expected_year, expected_quarter|
    test "sets the quarter and year correctly for year #{current_year} and month #{current_month}" do
      CreateVatReportJob.clear
      Rails.env.stub(:production?, true) do
        travel_to(Time.current.change(year: current_year, month: current_month, day: 2)) do
          GenerateFinancialReportsForPreviousQuarterJob.new.perform
        end
      end

      args = CreateVatReportJob.jobs.last["args"]
      assert_equal expected_quarter, args[0]
      assert_equal expected_year, args[1]
    end
  end
end
