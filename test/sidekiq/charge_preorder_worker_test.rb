# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skipped during bulk fixtures-only migration.
# Reason: :vcr + preorder_link.charge! deep chain (Stripe + chargeable + buyer mailers).
# Original spec: spec/sidekiq/charge_preorder_worker_spec.rb
class ChargePreorderWorkerTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/charge_preorder_worker_spec.rb — :vcr + preorder_link.charge! deep chain (Stripe + chargeable + buyer mailers)."
  end
end
