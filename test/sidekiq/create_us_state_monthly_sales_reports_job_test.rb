# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skipped during bulk fixtures-only migration.
# Reason: S3 + per-state breakdown + zip_tax_rate fixtures + merchant_account.
# Original spec: spec/sidekiq/create_us_state_monthly_sales_reports_job_spec.rb
class CreateUsStateMonthlySalesReportsJobTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/create_us_state_monthly_sales_reports_job_spec.rb — S3 + per-state breakdown + zip_tax_rate fixtures + merchant_account."
  end
end
