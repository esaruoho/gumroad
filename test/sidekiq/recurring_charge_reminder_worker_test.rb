# frozen_string_literal: true

require "test_helper"

class RecurringChargeReminderWorkerTest < ActiveSupport::TestCase
  setup do
    @subscription = subscriptions(:named_seller_product_subscription)
  end

  test "delivers reminder when subscription is alive, not in free trial, not completed, and reminders enabled" do
    @subscription.define_singleton_method(:alive?) { |**_opts| true }
    @subscription.define_singleton_method(:in_free_trial?) { false }
    @subscription.define_singleton_method(:charges_completed?) { false }
    @subscription.define_singleton_method(:send_renewal_reminders?) { true }

    sent = []
    CustomerLowPriorityMailer.stub(:subscription_renewal_reminder, ->(sid) {
      m = Object.new; m.define_singleton_method(:deliver_later) { |*_a, **_kw| sent << sid }; m
    }) do
      Subscription.stub(:find, ->(_id) { @subscription }) do
        RecurringChargeReminderWorker.new.perform(@subscription.id)
      end
    end
    assert_equal [@subscription.id], sent
  end

  test "skips when subscription is not alive" do
    @subscription.define_singleton_method(:alive?) { |**_opts| false }
    sent = []
    CustomerLowPriorityMailer.stub(:subscription_renewal_reminder, ->(_sid) {
      m = Object.new; m.define_singleton_method(:deliver_later) { |*_a, **_kw| sent << :x }; m
    }) do
      Subscription.stub(:find, ->(_id) { @subscription }) do
        RecurringChargeReminderWorker.new.perform(@subscription.id)
      end
    end
    assert_empty sent
  end

  test "skips when send_renewal_reminders? is false" do
    @subscription.define_singleton_method(:alive?) { |**_opts| true }
    @subscription.define_singleton_method(:in_free_trial?) { false }
    @subscription.define_singleton_method(:charges_completed?) { false }
    @subscription.define_singleton_method(:send_renewal_reminders?) { false }
    sent = []
    CustomerLowPriorityMailer.stub(:subscription_renewal_reminder, ->(_sid) {
      m = Object.new; m.define_singleton_method(:deliver_later) { |*_a, **_kw| sent << :x }; m
    }) do
      Subscription.stub(:find, ->(_id) { @subscription }) do
        RecurringChargeReminderWorker.new.perform(@subscription.id)
      end
    end
    assert_empty sent
  end
end
