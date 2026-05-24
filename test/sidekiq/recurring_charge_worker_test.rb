# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/sidekiq/recurring_charge_worker_spec.rb (56 FB refs, 423 lines).
#
# Blocker for batch 6b-B backfill: `:vcr`-tagged, includes ManageSubscriptionHelpers
# (spec/support/manage_subscription_helpers.rb — not loaded in Minitest lane). Every
# test builds `create(:subscription_product)` + `create(:subscription)` +
# `create(:purchase, is_original_subscription_purchase:)` and exercises real
# `subscription.charge!` paths via Stripe. The Subscription side already runs into the
# Subscription.create! / save!(validate: false) PaymentOption pitfall (skill); the worker
# also branches across `is_test_subscription`, free_purchase, period-end calculations,
# and credit_card states. Needs the full membership_purchase + payment_option +
# credit_card fixture suite + Stripe VCR cassettes. Out of scope.
class RecurringChargeWorkerTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/recurring_charge_worker_spec.rb — :vcr-tagged, includes ManageSubscriptionHelpers; 423 lines of subscription.charge! / Stripe / period-end branches across is_test_subscription / free_purchase / credit_card states. Needs membership_purchase + payment_option + credit_card fixture suite + Stripe VCR cassettes + spec/support helper port. Out of scope."
  end
end
