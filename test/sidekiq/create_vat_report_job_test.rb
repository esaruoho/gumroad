# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skipped during bulk fixtures-only migration.
# Reason: S3 + EU VAT report + zip_tax_rates + 21 FB refs.
# Original spec: spec/sidekiq/create_vat_report_job_spec.rb
class CreateVatReportJobTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/create_vat_report_job_spec.rb — S3 + EU VAT report + zip_tax_rates + 21 FB refs."
  end
end
