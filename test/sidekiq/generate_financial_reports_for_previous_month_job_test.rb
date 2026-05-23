# frozen_string_literal: true

require "test_helper"

class GenerateFinancialReportsForPreviousMonthJobTest < ActiveSupport::TestCase
  setup do
    CreateCanadaMonthlySalesReportJob.clear
    GenerateFeesByCreatorLocationReportJob.clear
    CreateUsStatesSalesSummaryReportJob.clear
    GenerateCanadaSalesReportJob.clear
    CreateGlobalSalesTaxSummaryReportJob.clear
  end

  test "does not generate any reports when the Rails environment is not production" do
    GenerateFinancialReportsForPreviousMonthJob.new.perform

    assert_equal 0, CreateCanadaMonthlySalesReportJob.jobs.size
    assert_equal 0, GenerateFeesByCreatorLocationReportJob.jobs.size
    assert_equal 0, CreateUsStatesSalesSummaryReportJob.jobs.size
    assert_equal 0, GenerateCanadaSalesReportJob.jobs.size
    assert_equal 0, CreateGlobalSalesTaxSummaryReportJob.jobs.size
  end

  test "generates reports when the Rails environment is production" do
    Rails.env.stub(:production?, true) do
      GenerateFinancialReportsForPreviousMonthJob.new.perform
    end

    canada_args = CreateCanadaMonthlySalesReportJob.jobs.last["args"]
    assert_kind_of Integer, canada_args[0]
    assert_kind_of Integer, canada_args[1]

    fees_args = GenerateFeesByCreatorLocationReportJob.jobs.last["args"]
    assert_kind_of Integer, fees_args[0]
    assert_kind_of Integer, fees_args[1]

    us_args = CreateUsStatesSalesSummaryReportJob.jobs.last["args"]
    assert_equal Compliance::Countries::TAXABLE_US_STATE_CODES, us_args[0]
    assert_kind_of Integer, us_args[1]
    assert_kind_of Integer, us_args[2]

    canada_sales_args = GenerateCanadaSalesReportJob.jobs.last["args"]
    assert_kind_of Integer, canada_sales_args[0]
    assert_kind_of Integer, canada_sales_args[1]

    global_args = CreateGlobalSalesTaxSummaryReportJob.jobs.last["args"]
    assert_kind_of Integer, global_args[0]
    assert_kind_of Integer, global_args[1]
  end
end
