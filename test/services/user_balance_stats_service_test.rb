# frozen_string_literal: true

require "test_helper"

class UserBalanceStatsServiceTest < ActiveSupport::TestCase
  test "TODO: migrate spec/services/user_balance_stats_service_spec.rb (18 FB refs)" do
    skip "Awaiting fixtures migration: UserBalanceStatsService aggregates over PurchaseSearchService (Elasticsearch). Per skill ref skip-batch-authorization, ES aggregation chain cannot be reasonably stubbed inline. This is also the service other specs stub — when other specs need it, they should mock UserBalanceStatsService.new(...).fetch directly rather than re-running it."
  end
end
