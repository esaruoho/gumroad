# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during bulk fixtures-only migration.
# Original: spec/services/exports/tax_summary/annual_spec.rb
# Reason: VCR-tagged; depends on PaymentsHelper#create_payment_with_purchase (creates 12 payments
# with purchases over 12 months), encrypted strongbox fields on UserComplianceInfo, generates and
# uploads a CSV to S3. Multi-factory + S3 round-trip. Deferred.
class Exports::TaxSummary::AnnualTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — VCR + 12-payment factory chain + S3 CSV upload" do
    skip "TODO: migrate spec/services/exports/tax_summary/annual_spec.rb (VCR, PaymentsHelper, S3 CSV)"
  end
end
