# frozen_string_literal: true

require "test_helper"

class Exports::Payouts::CsvTest < ActiveSupport::TestCase
  test "HEADERS, TOTALS_COLUMN_NAME, and TOTALS_FIELDS are configured for payout CSV" do
    assert_equal "Totals", Exports::Payouts::Csv::TOTALS_COLUMN_NAME
    assert_includes Exports::Payouts::Csv::HEADERS, "Type"
    assert_includes Exports::Payouts::Csv::HEADERS, "Sale Price ($)"
    assert_includes Exports::Payouts::Csv::HEADERS, "Net Total ($)"

    Exports::Payouts::Csv::TOTALS_FIELDS.each do |field|
      assert_includes Exports::Payouts::Csv::HEADERS, field,
                      "TOTALS_FIELDS column #{field} must appear in HEADERS"
    end
  end

  test "#calculate_totals sums currency columns across data rows" do
    service = Exports::Payouts::Csv.new(payment: Payment.new)

    row1 = Array.new(Exports::Payouts::Csv::HEADERS.size)
    row1[Exports::Payouts::Csv::HEADERS.index("Sale Price ($)")] = "10.00"
    row1[Exports::Payouts::Csv::HEADERS.index("Gumroad Fees ($)")] = "1.00"

    row2 = Array.new(Exports::Payouts::Csv::HEADERS.size)
    row2[Exports::Payouts::Csv::HEADERS.index("Sale Price ($)")] = "5.00"
    row2[Exports::Payouts::Csv::HEADERS.index("Gumroad Fees ($)")] = "0.50"

    totals = service.send(:calculate_totals, [row1, row2])
    assert_in_delta 15.0, totals["Sale Price ($)"], 0.001
    assert_in_delta 1.5, totals["Gumroad Fees ($)"], 0.001
  end

  test "#generate_totals_row places totals values in the right columns" do
    service = Exports::Payouts::Csv.new(payment: Payment.new)
    totals = { "Sale Price ($)" => 12.34, "Gumroad Fees ($)" => 1.20 }

    row = service.send(:generate_totals_row, totals)

    assert_equal "Totals", row[0]
    assert_equal 12.34, row[Exports::Payouts::Csv::HEADERS.index("Sale Price ($)")]
    assert_equal 1.2, row[Exports::Payouts::Csv::HEADERS.index("Gumroad Fees ($)")]
  end

  # TODO: The full payout export integration (#perform pulling from
  # balance_transactions, refunds, chargebacks, credits) requires a payouts
  # + balance_transactions fixture surface that does not yet exist on this
  # branch. Original: spec/services/exports/payouts/csv_spec.rb (FactoryBot-heavy).
end
