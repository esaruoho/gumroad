# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skipped during bulk fixtures-only migration.
# Reason: Gift purchase chain (gifter/giftee state machine) + subscription original purchase. State machine transitions need full chargeable/setup_intent infra.
# Original spec: spec/sidekiq/create_licenses_for_existing_customers_worker_spec.rb
class CreateLicensesForExistingCustomersWorkerTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/create_licenses_for_existing_customers_worker_spec.rb — Gift purchase chain (gifter/giftee state machine) + subscription original purchase. State machine transitions need full chargeable/setup_intent infra."
  end
end
