# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skipped during bulk fixtures-only migration.
# Reason: :vcr + Stripe Connect account chain + merchant_accounts + bank reversal flow. Heavy Stripe integration.
# Original spec: spec/sidekiq/collect_unclaimed_balances_of_inactive_stripe_accounts_job_spec.rb
class CollectUnclaimedBalancesOfInactiveStripeAccountsJobTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/collect_unclaimed_balances_of_inactive_stripe_accounts_job_spec.rb — :vcr + Stripe Connect account chain + merchant_accounts + bank reversal flow. Heavy Stripe integration."
  end
end
