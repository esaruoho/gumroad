# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/modules/product/caching_spec.rb (8 FactoryBot refs, 315 lines).
#
# Blocker for batch A backfill: ~30% of the spec (`#invalidate_cache`,
# `.scoped_cache_key`, `#scoped_cache_keys`) is genuinely tractable with the
# existing `links(:basic_user_product)` fixture and Rails.cache stubs. However
# the remaining ~70% covers `Product::Caching.dashboard_collection_data`, whose
# behaviour delegates to `Product::Stats#successful_sales_count` /
# `#monthly_recurring_revenue` / `#revenue_pending` / `#total_usd_cents`. All
# four hit Elasticsearch aggregations (cf. mailer-pitfalls-quickref P-M1 for
# `User#mailer_level` → the same nil-aggregation crash pattern). The global
# EsClient fake in `test/test_helper.rb` returns
# `{"hits" => ..., "count" => 0}` with no aggregations → `.value` calls dereference
# nil. Migrating the cache-key half only would violate the "don't half-migrate"
# rule (#4). A full migration needs an ES-aggregation stub harness (per-stat
# method `stub_class_method` registry, which is heavier than this single file
# justifies). Out of scope for batch A.
class ModulesProductCachingTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/modules/product/caching_spec.rb — dashboard_collection_data branch delegates to Product::Stats methods that hit Elasticsearch aggregations; EsClient fake returns no aggregations (same crash family as mailer P-M1). Needs an ES-stub harness."
  end
end
