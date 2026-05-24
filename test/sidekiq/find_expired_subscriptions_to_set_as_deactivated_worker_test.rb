# frozen_string_literal: true

require "test_helper"

class FindExpiredSubscriptionsToSetAsDeactivatedWorkerTest < ActiveSupport::TestCase
  test "queues subscriptions that should be set as deactivated" do
    not_queued = [
      subscriptions(:active_expired_sub_default),
      subscriptions(:cancelled_future_sub),
      subscriptions(:cancelled_past_test_sub),
      subscriptions(:cancelled_past_deactivated_sub),
    ]
    queued = [
      subscriptions(:cancelled_past_sub),
      subscriptions(:failed_past_sub),
      subscriptions(:ended_past_sub),
    ]

    SetSubscriptionAsDeactivatedWorker.jobs.clear
    FindExpiredSubscriptionsToSetAsDeactivatedWorker.new.perform
    enqueued_ids = SetSubscriptionAsDeactivatedWorker.jobs.map { |j| j["args"].first }

    not_queued.each { |s| refute_includes enqueued_ids, s.id }
    queued.each { |s| assert_includes enqueued_ids, s.id }
  end
end
