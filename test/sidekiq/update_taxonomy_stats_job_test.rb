# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/sidekiq/update_taxonomy_stats_job_spec.rb (6 FactoryBot refs, 42 lines).
#
# Blocker for batch 6b-B backfill: ES-bound. Test calls `recreate_model_index(Purchase)`
# + `index_model_records(Purchase)` (spec/support/elasticsearch helpers, not loaded in
# the Minitest lane), then asserts on the job-populated TaxonomyStat rows whose
# values are computed from `Purchase.search(...)` aggregations under the hood.
# Per the leaf-backfill-pitfalls skill ("ES-bound Product::Searchable specs: keep
# skip-stub, don't half-migrate"), this needs a dedicated ES-indexing harness;
# defer.
class UpdateTaxonomyStatsJobTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/update_taxonomy_stats_job_spec.rb — ES-bound: uses recreate_model_index(Purchase) + index_model_records(Purchase) helpers (spec/support/elasticsearch.rb, not loaded in Minitest lane) and asserts on TaxonomyStat rows computed from Purchase ES aggregations. Skip per leaf-backfill ES-bound pitfall."
  end
end
