# frozen_string_literal: true

require "test_helper"

class EndSubscriptionWorkerTest < ActiveSupport::TestCase
  setup do
    @subscription = subscriptions(:named_seller_product_subscription)
  end

  # Returns [worker_result, called?]; replaces Subscription.find so we can stub
  # the per-instance behaviour without RSpec's any_instance helper.
  def run_with_stubs(alive:, charges_completed:, &block)
    called = false
    fake = @subscription
    fake.define_singleton_method(:alive?) { |**_| alive }
    fake.define_singleton_method(:charges_completed?) { charges_completed }
    fake.define_singleton_method(:end_subscription!) { called = true }
    Subscription.stub(:find, ->(id) { id == @subscription.id ? fake : Subscription.find_by(id: id) }) do
      EndSubscriptionWorker.new.perform(@subscription.id)
    end
    called
  end

  test "does not call end_subscription! on test subscriptions" do
    @subscription.update_columns(flags: 1) # is_test_subscription = true
    refute run_with_stubs(alive: true, charges_completed: true)
  end

  test "calls end_subscription! on subscriptions that are alive and charges completed" do
    @subscription.update_columns(cancelled_at: nil, failed_at: nil, ended_at: nil)
    assert run_with_stubs(alive: true, charges_completed: true)
  end

  test "does not call end_subscription! when subscription is not alive" do
    refute run_with_stubs(alive: false, charges_completed: true)
  end

  test "does not call end_subscription! when charges_completed? is false" do
    refute run_with_stubs(alive: true, charges_completed: false)
  end

  # Sanity check that the real alive? returns false in each terminal state.
  test "real alive? is false when subscription is cancelled in the past" do
    @subscription.update_columns(cancelled_at: 1.day.ago)
    refute @subscription.reload.alive?(include_pending_cancellation: false)
  end

  test "real alive? is false when subscription has failed" do
    @subscription.update_columns(failed_at: Time.current)
    refute @subscription.reload.alive?(include_pending_cancellation: false)
  end

  test "real alive? is false when subscription has ended" do
    @subscription.update_columns(ended_at: Time.current)
    refute @subscription.reload.alive?(include_pending_cancellation: false)
  end
end
