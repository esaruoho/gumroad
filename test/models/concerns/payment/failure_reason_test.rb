# frozen_string_literal: true

require "test_helper"

class Payment::FailureReasonTest < ActiveSupport::TestCase
  setup do
    @payment = payments(:failure_reason_payment)
  end

  test "doesn't add payout note when failure_reason is not present" do
    assert_no_difference -> { @payment.user.comments.count } do
      @payment.mark_failed!
    end
  end

  test "PAYPAL: adds payout note when solution is present" do
    assert_difference -> { @payment.user.comments.count }, 1 do
      @payment.mark_failed!("PAYPAL 11711")
    end

    expected = "Payout via Paypal on #{@payment.created_at} failed because per-transaction sending limit exceeded. " \
               "Solution: Contact PayPal to get receiving limit on the account increased. " \
               "If that's not possible, Gumroad can split their payout, please contact Gumroad Support."
    assert_equal expected, @payment.user.comments.last.content
  end

  test "PAYPAL: doesn't add payout note when solution is not present" do
    assert_no_difference -> { @payment.user.comments.count } do
      @payment.mark_failed!("PAYPAL unknown_failure_reason")
    end
  end

  test "Stripe: adds payout note when solution is present" do
    @payment.update!(processor: PayoutProcessorType::STRIPE)

    assert_difference -> { @payment.user.comments.count }, 1 do
      @payment.mark_failed!("account_closed")
    end

    expected = "Payout via Stripe on #{@payment.created_at} failed because the bank account has been closed. " \
               "Solution: Use another bank account."
    assert_equal expected, @payment.user.comments.last.content
  end

  test "Stripe: bank_account_not_found_at_stripe adds payout note explaining re-add" do
    @payment.update!(processor: PayoutProcessorType::STRIPE)

    assert_difference -> { @payment.user.comments.count }, 1 do
      @payment.mark_failed!(Payment::FailureReason::BANK_ACCOUNT_NOT_FOUND_AT_STRIPE)
    end

    expected = "Payout via Stripe on #{@payment.created_at} failed because the bank account on file at Stripe was replaced, " \
               "so payouts can no longer be sent to the saved reference. " \
               "Solution: Re-add the bank account in payout settings to refresh the saved reference."
    assert_equal expected, @payment.user.comments.last.content
  end

  test "Stripe: doesn't add payout note when solution is not present" do
    @payment.update!(processor: PayoutProcessorType::STRIPE)
    assert_no_difference -> { @payment.user.comments.count } do
      @payment.mark_failed!("unknown_failure_reason")
    end
  end
end
