# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skipped during bulk fixtures-only migration.
# Reason: :vcr cassette + membership_product/subscription chain + credit_card factory. VCR cassettes don't have a clean Minitest port.
# Original spec: spec/sidekiq/charge_declined_reminder_worker_spec.rb
class ChargeDeclinedReminderWorkerTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/charge_declined_reminder_worker_spec.rb — :vcr cassette + membership_product/subscription chain + credit_card factory. VCR cassettes don't have a clean Minitest port."
  end
end
