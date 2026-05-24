# frozen_string_literal: true

require "test_helper"

class ProcessPaymentWorkerTest < ActiveSupport::TestCase
  test "does nothing if the payment is not in processing state" do
    non_processing = %i[
      process_pw_creating
      process_pw_unclaimed
      process_pw_failed
      process_pw_completed
      process_pw_reversed
      process_pw_returned
      process_pw_cancelled
    ].map { |k| payments(k) }

    called = false
    StripePayoutProcessor.stub(:process_payments, ->(_) { called = true }) do
      non_processing.each { |p| ProcessPaymentWorker.new.perform(p.id) }
    end

    refute called
  end

  test "processes the payment if it is in processing state" do
    payment = payments(:process_pw_processing)
    captured_args = nil

    StripePayoutProcessor.stub(:process_payments, ->(args) { captured_args = args }) do
      ProcessPaymentWorker.new.perform(payment.id)
    end

    assert_equal [payment], captured_args
  end
end
