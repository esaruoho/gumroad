# frozen_string_literal: true

require "test_helper"

class AdminFundsCsvReportServiceTest < ActiveSupport::TestCase
  test "generates a CSV for funds received report with zero purchases" do
    report = FundsReceivedReports.funds_received_report(1, 2022)
    csv = AdminFundsCsvReportService.new(report).generate
    parsed = CSV.parse(csv)
    assert_equal [
      ["Purchases", "PayPal", "total_transaction_count", "0"],
      ["", "", "total_transaction_cents", "0"],
      ["", "", "gumroad_tax_cents", "0"],
      ["", "", "affiliate_credit_cents", "0"],
      ["", "", "fee_cents", "0"],
      ["", "Stripe", "total_transaction_count", "0"],
      ["", "", "total_transaction_cents", "0"],
      ["", "", "gumroad_tax_cents", "0"],
      ["", "", "affiliate_credit_cents", "0"],
      ["", "", "fee_cents", "0"],
    ], parsed
  end

  test "generates a CSV for deferred refunds report with zero refunds" do
    report = DeferredRefundsReports.deferred_refunds_report(1, 2022)
    csv = AdminFundsCsvReportService.new(report).generate
    parsed = CSV.parse(csv)
    assert_equal [
      ["Purchases", "PayPal", "total_transaction_count", "0"],
      ["", "", "total_transaction_cents", "0"],
      ["", "", "gumroad_tax_cents", "0"],
      ["", "", "affiliate_credit_cents", "0"],
      ["", "", "fee_cents", "0"],
      ["", "Stripe", "total_transaction_count", "0"],
      ["", "", "total_transaction_cents", "0"],
      ["", "", "gumroad_tax_cents", "0"],
      ["", "", "affiliate_credit_cents", "0"],
      ["", "", "fee_cents", "0"],
    ], parsed
  end
end
