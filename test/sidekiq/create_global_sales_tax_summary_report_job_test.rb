# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skipped during bulk fixtures-only migration.
# Reason: S3 upload + global tax matrix across countries + zip_tax_rate seeds; 20 FB refs but heavy data model.
# Original spec: spec/sidekiq/create_global_sales_tax_summary_report_job_spec.rb
class CreateGlobalSalesTaxSummaryReportJobTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/create_global_sales_tax_summary_report_job_spec.rb — S3 upload + global tax matrix across countries + zip_tax_rate seeds; 20 FB refs but heavy data model."
  end
end
