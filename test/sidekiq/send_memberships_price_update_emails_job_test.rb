# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/sidekiq/send_memberships_price_update_emails_job_spec.rb (7 FB refs, 62 lines).
#
# Blocker for batch 6b-B backfill: `subscription_plan_changes` table has no fixtures
# yet in test/fixtures and the spec creates 5 distinct SubscriptionPlanChange rows
# (combinations of `for_product_price_change`, `applied`, `deleted_at`,
# `notified_subscriber_at`, `effective_on` 8.days.from_now). The base `:subscription`
# factory itself trips the skill pitfall "Subscription.create! / save!(validate: false)
# both blow up — must use raw SQL INSERT escape hatch" because the
# update_last_payment_option callback fires on empty payment_options. Combining the
# raw-INSERT subscription path with 5 new plan-change rows + applicable_for_product_price_change_as_of
# date-window assertions is out of scope for a leaf backfill.
class SendMembershipsPriceUpdateEmailsJobTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/send_memberships_price_update_emails_job_spec.rb — subscription_plan_changes has no fixtures; spec creates 5 plan-change rows across applicable/non-applicable branches and the base :subscription factory trips the Subscription.create! / save!(validate: false) PaymentOption pitfall. Out of scope."
  end
end
