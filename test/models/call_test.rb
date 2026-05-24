# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Call spec (318 LOC, 47 create() refs) needs the
# `call_product` + `:available_for_a_year` trait (Link + CallLimitationInfo
# + 7-days-a-week CallAvailability fixtures) plus successful_purchase chain
# (Purchase via cc_token_chargeable, full validation pass) and Sidekiq job
# enqueue assertions (ScheduleCallReminderJob, ScheduleSubmitVideoCallUrlReminderJob).
# `call_product` factory alone wires Link + CallLimitationInfo + 4 sub-rows;
# multiplied by the calls-on-a-given-date matrix. Out of scope for mechanical
# model backfill.
#
# Original spec: spec/models/call_spec.rb
class CallTest < ActiveSupport::TestCase
  test "TODO: migrate — call_product + availability + successful_purchase + Sidekiq" do
    skip "47 create() refs through call_product (Link + CallLimitationInfo + CallAvailability) + successful_purchase + ScheduleCallReminderJob enqueues. Out of scope for mechanical model backfill."
  end
end
