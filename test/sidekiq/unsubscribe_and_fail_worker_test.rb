# frozen_string_literal: true

require "test_helper"

class UnsubscribeAndFailWorkerTest < ActiveSupport::TestCase
  setup do
    @subscription = subscriptions(:named_seller_product_subscription)
  end

  test "returns early if subscription is not alive (failed_at present)" do
    @subscription.update_columns(failed_at: 1.day.ago)
    called = false
    @subscription.define_singleton_method(:unsubscribe_and_fail!) { called = true }
    Subscription.stub(:find, ->(_id) { @subscription }) do
      UnsubscribeAndFailWorker.new.perform(@subscription.id)
    end
    refute called
  end

  test "returns early when subscription is a test_subscription" do
    @subscription.update_columns(flags: (@subscription.flags || 0) | (1 << 0)) # is_test_subscription (has_flags 1)
    @subscription.define_singleton_method(:overdue_for_charge?) { true }
    called = false
    @subscription.define_singleton_method(:unsubscribe_and_fail!) { called = true }
    Subscription.stub(:find, ->(_id) { @subscription }) do
      UnsubscribeAndFailWorker.new.perform(@subscription.id)
    end
    refute called
  end

  test "returns early when subscription is not overdue_for_charge" do
    @subscription.define_singleton_method(:overdue_for_charge?) { false }
    called = false
    @subscription.define_singleton_method(:unsubscribe_and_fail!) { called = true }
    Subscription.stub(:find, ->(_id) { @subscription }) do
      UnsubscribeAndFailWorker.new.perform(@subscription.id)
    end
    refute called
  end

  test "invokes unsubscribe_and_fail! when alive, not test, and overdue" do
    @subscription.define_singleton_method(:overdue_for_charge?) { true }
    called = false
    @subscription.define_singleton_method(:unsubscribe_and_fail!) { called = true }
    Subscription.stub(:find, ->(_id) { @subscription }) do
      UnsubscribeAndFailWorker.new.perform(@subscription.id)
    end
    assert called
  end
end
