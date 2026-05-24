# frozen_string_literal: true

require "test_helper"

class Exports::Payouts::AnnualTest < ActiveSupport::TestCase
  setup do
    @year = 2019
    @user = users(:payout_annual_seller)
    payments(:payout_annual_outside_payment).update_columns(state: "failed")
  end

  test "#perform shows all activity related to the yearly payout" do
    parsed_csv = parsed_annual_csv
    sale = purchases(:payout_annual_purchase)

    assert_includes parsed_csv, Exports::Payouts::Csv::HEADERS
    assert_includes parsed_csv, sale_summary(sale)
    assert_equal ["Totals", nil, nil, nil, nil, nil, "0.0", "0.0", "15.0", "5.0", "10.0"], parsed_csv.last
  end

  test "#perform returns total_amount from the yearly payout" do
    data = Exports::Payouts::Annual.new(user: @user, year: @year).perform

    assert_equal 1000, (data[:total_amount] * 100.0).round
  ensure
    data&.fetch(:csv_file)&.close
    data&.fetch(:csv_file)&.unlink
  end

  test "#perform returns no data if no payments exist" do
    data = Exports::Payouts::Annual.new(user: users(:basic_user), year: @year).perform

    assert_nil data[:csv_file]
    assert_equal 0, data[:total_amount]
  end

  test "#perform returns no data for failed payments" do
    parsed_csv = parsed_annual_csv

    assert_not_includes parsed_csv, sale_summary(purchases(:payout_annual_failed_purchase))
  end

  test "#perform does not return sales falling on days not in the given year" do
    payments(:payout_annual_outside_payment).update_columns(state: "completed")

    parsed_csv = parsed_annual_csv

    assert_not_includes parsed_csv, sale_summary(purchases(:payout_annual_outside_purchase))
  end

  private
    def parsed_annual_csv
      data = Exports::Payouts::Annual.new(user: @user, year: @year).perform
      CSV.parse(data[:csv_file].read)
    ensure
      data&.fetch(:csv_file)&.close
      data&.fetch(:csv_file)&.unlink
    end

    def csv_safe(value)
      return value if value.nil?

      str = value.to_s
      return value if str.empty?

      first = str[0]
      if first == "+" || first == "-"
        return value if str[1..]&.match?(/\A\d+\.?\d*\z/)
      end

      %w[= @ | % \r \t + -].include?(first) ? "'#{value}" : value
    end

    def sale_summary(sale)
      CSV.parse([
        "Sale",
        sale.succeeded_at.to_date.to_s,
        csv_safe(sale.external_id),
        sale.link.name,
        sale.full_name,
        sale.purchaser_email_or_email,
        sale.tax_dollars,
        sale.shipping_dollars,
        sale.price_dollars,
        sale.fee_dollars,
        sale.net_total,
      ].to_csv).first
    end
end
