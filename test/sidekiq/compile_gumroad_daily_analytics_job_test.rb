# frozen_string_literal: true

require "test_helper"

class CompileGumroadDailyAnalyticsJobTest < ActiveSupport::TestCase
  test "TODO: migrate spec/sidekiq/compile_gumroad_daily_analytics_job_spec.rb (needs 8 purchase fixtures with distinct sellers + 2 service_charges + 1 gumroad_daily_analytic — purchase factory chain is heavy)" do
    skip "Awaiting fixtures migration: multi-table purchase/service_charge/analytic fixture chain with specific timestamps + fee math"
  end
end
