# frozen_string_literal: true

require "test_helper"

class Exports::Payouts::CsvTest < ActiveSupport::TestCase
  test "TODO" do
    skip "migrate from spec/services/exports/payouts/csv_spec.rb " \
         "(FB=7 but covers full Purchase + Payment + PayPal/Stripe Connect merchant accounts + " \
         "Credit/Refund/Dispute/AffiliateCredit lifecycle across multiple travel_to windows; " \
         "requires payouts/credits/refunds/balance_transactions fixture surface that doesn't " \
         "yet exist on the migration branch)"
  end
end
