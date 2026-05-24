# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skipped during bulk fixtures-only migration.
# Reason: S3 upload chain + sales reports presenter; need product/purchase/tax matrix + merchant_account fixtures.
# Original spec: spec/sidekiq/create_canada_monthly_sales_report_job_spec.rb
class CreateCanadaMonthlySalesReportJobTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/create_canada_monthly_sales_report_job_spec.rb — S3 upload chain + sales reports presenter; need product/purchase/tax matrix + merchant_account fixtures."
  end
end
