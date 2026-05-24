# frozen_string_literal: true

require "test_helper"

class SendPaypalTopupNotificationJobTest < ActiveSupport::TestCase
  def fake_service(payout:, current:, in_transit:)
    fake = Object.new
    fake.define_singleton_method(:payout_amount_cents) { payout }
    fake.define_singleton_method(:current_balance_cents) { current }
    fake.define_singleton_method(:topup_in_transit_cents) { in_transit }
    fake.define_singleton_method(:topup_amount_cents) { payout - current - in_transit }
    fake.define_singleton_method(:topup_needed?) { (payout - current - in_transit) > 0 }
    fake
  end

  def with_service(service)
    PaypalBalanceCheckService.stub(:new, service) do
      Rails.env.stub(:production?, true) do
        yield
      end
    end
  end

  def assert_redis_topup_needed(expected)
    actual = $redis.get(RedisKey.paypal_topup_needed)
    assert_equal expected, actual
  end

  setup do
    $redis.del(RedisKey.paypal_topup_needed)
  end

  test "enqueues a topup-needed notification and sets redis key to true" do
    service = fake_service(payout: 367_425_18, current: 125_000_00, in_transit: 0)
    with_service(service) do
      SendPaypalTopupNotificationJob.new.perform
    end

    expected_msg = "PayPal balance needs to be $367,425.18 by Friday to payout all creators.\n" \
                   "Current PayPal balance is $125,000.\n" \
                   "A top-up of $242,425.18 is needed."

    assert InternalNotificationWorker.jobs.any? { |j| j["args"] == ["payments", "PayPal Top-up", expected_msg, "red"] },
           "expected red top-up enqueue; got #{InternalNotificationWorker.jobs.map { |j| j["args"] }.inspect}"
    assert_redis_topup_needed("true")
  end

  test "includes the in-transit amount in the message" do
    service = fake_service(payout: 367_425_18, current: 125_000_00, in_transit: 100_000_00)
    with_service(service) do
      SendPaypalTopupNotificationJob.new.perform
    end

    expected_msg = "PayPal balance needs to be $367,425.18 by Friday to payout all creators.\n" \
                   "Current PayPal balance is $125,000.\n" \
                   "Top-up amount in transit is $100,000.\n" \
                   "A top-up of $142,425.18 is needed."

    assert InternalNotificationWorker.jobs.any? { |j| j["args"] == ["payments", "PayPal Top-up", expected_msg, "red"] }
  end

  test "sends a green no-top-up-required notification and sets redis key to false" do
    service = fake_service(payout: 367_425_18, current: 125_000_00, in_transit: 300_000_00)
    with_service(service) do
      SendPaypalTopupNotificationJob.new.perform
    end

    expected_msg = "PayPal balance needs to be $367,425.18 by Friday to payout all creators.\n" \
                   "Current PayPal balance is $125,000.\n" \
                   "Top-up amount in transit is $300,000.\n" \
                   "No more top-up required."

    assert InternalNotificationWorker.jobs.any? { |j| j["args"] == ["payments", "PayPal Top-up", expected_msg, "green"] }
    assert_redis_topup_needed("false")
  end

  test "sends a notification when notify_only_if_topup_needed is true and topup is needed" do
    service = fake_service(payout: 367_425_18, current: 125_000_00, in_transit: 0)
    with_service(service) do
      SendPaypalTopupNotificationJob.new.perform(true)
    end

    expected_msg = "PayPal balance needs to be $367,425.18 by Friday to payout all creators.\n" \
                   "Current PayPal balance is $125,000.\n" \
                   "A top-up of $242,425.18 is needed."

    assert InternalNotificationWorker.jobs.any? { |j| j["args"] == ["payments", "PayPal Top-up", expected_msg, "red"] }
  end

  test "does not send a notification when notify_only_if_topup_needed is true and topup is not needed" do
    initial_jobs = InternalNotificationWorker.jobs.size
    service = fake_service(payout: 367_425_18, current: 125_000_00, in_transit: 300_000_00)
    with_service(service) do
      SendPaypalTopupNotificationJob.new.perform(true)
    end

    assert_equal initial_jobs, InternalNotificationWorker.jobs.size
    assert_redis_topup_needed("false")
  end
end
