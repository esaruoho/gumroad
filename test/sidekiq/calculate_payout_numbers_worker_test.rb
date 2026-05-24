# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skipped during bulk fixtures-only migration.
# Reason: Requires Elasticsearch (:elasticsearch_wait_for_refresh) + recreate_model_indices(Purchase) + :sidekiq_inline. ES infra is skip-batch per skill.
# Original spec: spec/sidekiq/calculate_payout_numbers_worker_spec.rb
class CalculatePayoutNumbersWorkerTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/calculate_payout_numbers_worker_spec.rb — Requires Elasticsearch (:elasticsearch_wait_for_refresh) + recreate_model_indices(Purchase) + :sidekiq_inline. ES infra is skip-batch per skill."
  end
end
