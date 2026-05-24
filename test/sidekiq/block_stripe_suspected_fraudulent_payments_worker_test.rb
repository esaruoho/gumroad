# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skipped during bulk fixtures-only migration.
# Reason: Helper::Client webhook + Stripe charge ID parsing + admin user; uses expect_any_instance_of which has no direct Minitest equivalent. Helper::Client stubbing chain is brittle. Skip per skill heuristic.
# Original spec: spec/sidekiq/block_stripe_suspected_fraudulent_payments_worker_spec.rb
class BlockStripeSuspectedFraudulentPaymentsWorkerTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/block_stripe_suspected_fraudulent_payments_worker_spec.rb — Helper::Client webhook + Stripe charge ID parsing + admin user; uses expect_any_instance_of which has no direct Minitest equivalent. Helper::Client stubbing chain is brittle. Skip per skill heuristic."
  end
end
