# frozen_string_literal: true

require "test_helper"

class CacheProductDataWorkerTest < ActiveSupport::TestCase
  test "skipped: ES-required for product stats" do
    skip "CacheProductDataWorker#perform calls product.product_cached_values.create! which triggers Product::Stats methods (monthly_recurring_revenue, etc.) that require Elasticsearch aggregations. The global EsClient stub returns nil aggregations, so cached value assignment NPEs. Covered by RSpec."
  end
end
