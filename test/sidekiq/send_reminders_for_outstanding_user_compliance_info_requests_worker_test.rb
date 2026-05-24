# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/sidekiq/send_reminders_for_outstanding_user_compliance_info_requests_worker_spec.rb (31 FB refs, 170 lines).
#
# Blocker for batch 6b-B backfill: Builds 9 users + 11 `user_compliance_info_request` rows
# with `record_email_sent!` timing branches across the 0/1/2/3/8/10-day windows, plus
# a `flag_for_fraud!` + `suspend_for_fraud!` admin chain. The
# `user_compliance_info_requests` table has no fixtures yet, and each test asserts on
# `have_enqueued_mail(...).with(user.id, field_needed:)` for several combinations.
# Net-new fixture investment is large and the time-window assertions need `travel_to`
# discipline. Out of scope.
class SendRemindersForOutstandingUserComplianceInfoRequestsWorkerTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/send_reminders_for_outstanding_user_compliance_info_requests_worker_spec.rb — 9 users × 11 user_compliance_info_request rows across time-window branches (0/1/2/3/8/10 days), plus flag_for_fraud!/suspend_for_fraud! admin chain. user_compliance_info_requests has no fixture file yet. Out of scope."
  end
end
