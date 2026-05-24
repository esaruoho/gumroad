# frozen_string_literal: true

require "test_helper"

class RetryFailedPaypalPayoutsWorkerTest < ActiveSupport::TestCase
  test "calls Payouts.create_payments_for_balances_up_to_date_for_users when a failed paypal payment exists" do
    failed_payment = payments(:retry_failed_paypal_payment)
    failed_payment.update_columns(payout_period_end_date: User::PayoutSchedule.manual_payout_end_date)

    called_args = nil
    Payouts.stub(:create_payments_for_balances_up_to_date_for_users,
                 ->(date, processor, users, **opts) { called_args = [date, processor, users.to_a, opts] }) do
      RetryFailedPaypalPayoutsWorker.new.perform
    end

    refute_nil called_args, "expected Payouts.create_payments_for_balances_up_to_date_for_users to be called"
    assert_equal User::PayoutSchedule.manual_payout_end_date, called_args[0]
    assert_equal PayoutProcessorType::PAYPAL, called_args[1]
    assert_equal [failed_payment.user_id], called_args[2].map(&:id)
    assert_equal({ perform_async: true, retrying: true }, called_args[3])
  end

  test "does nothing if no failed payouts" do
    # Ensure no failed paypal payments match the current manual_payout_end_date
    Payment.where(state: "failed", processor: PayoutProcessorType::PAYPAL).update_all(payout_period_end_date: 100.years.ago.to_date)
    called = false
    Payouts.stub(:create_payments_for_balances_up_to_date_for_users, ->(*_args, **_kwargs) { called = true }) do
      RetryFailedPaypalPayoutsWorker.new.perform
    end
    refute called
  end
end
