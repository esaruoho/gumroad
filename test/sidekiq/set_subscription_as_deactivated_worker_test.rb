# frozen_string_literal: true

require "test_helper"

class SetSubscriptionAsDeactivatedWorkerTest < ActiveSupport::TestCase
  test "sets subscription as deactivated when cancelled in the past" do
    subscription = subscriptions(:deactivated_worker_cancelled_past_subscription)
    SetSubscriptionAsDeactivatedWorker.new.perform(subscription.id)
    refute_nil subscription.reload.deactivated_at
  end

  test "does not set subscriptions cancelled in the future as deactivated" do
    subscription = subscriptions(:deactivated_worker_cancelled_future_subscription)
    SetSubscriptionAsDeactivatedWorker.new.perform(subscription.id)
    assert_nil subscription.reload.deactivated_at
  end

  test "does not set alive subscription as deactivated" do
    subscription = subscriptions(:deactivated_worker_alive_subscription)
    SetSubscriptionAsDeactivatedWorker.new.perform(subscription.id)
    assert_nil subscription.reload.deactivated_at
  end
end
