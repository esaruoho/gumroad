# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skipped during bulk fixtures-only migration.
# Reason: S3 + GST report + India merchant_account + multiple purchase shapes; touches Compliance::CountryCheck.
# Original spec: spec/sidekiq/create_india_sales_report_job_spec.rb
class CreateIndiaSalesReportJobTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/create_india_sales_report_job_spec.rb — S3 + GST report + India merchant_account + multiple purchase shapes; touches Compliance::CountryCheck."
  end
end
