# frozen_string_literal: true

require "test_helper"

class UpdateUserBalanceStatsCacheWorkerTest < ActiveSupport::TestCase
  test "skipped: UserBalanceStatsService relies on ES aggregations" do
    skip "UserBalanceStatsService#write_cache calls #generate which depends on user.sales_cents_total / PurchaseSearchService.aggregations chain. Per migration policy, ES-aggregation-chain workers are skip-batch."
  end
end
