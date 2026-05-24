# frozen_string_literal: true

require "test_helper"

class HandlePayoutReversedWorkerTest < ActiveSupport::TestCase
  setup do
    @payment = payments(:payout_annual_completed_payment)
    @reversing_payout_id = "reversing-payout-id"
    @stripe_account_id = "stripe-account-id"
  end

  def reversing_payout(payout_status:, balance_transaction_status:)
    {
      "object" => "payout",
      "id" => "reversal_payout_id",
      "failure_code" => nil,
      "automatic" => false,
      "status" => payout_status,
      "balance_transaction" => { "status" => balance_transaction_status }
    }
  end

  test "calls StripePayoutProcessor.handle_stripe_event_payout_reversed when reversing payout succeeded" do
    Stripe::Payout.stub(:retrieve, ->(_args, _opts) { reversing_payout(payout_status: "paid", balance_transaction_status: "available") }) do
      seen = nil
      StripePayoutProcessor.stub(:handle_stripe_event_payout_reversed, ->(payment, rev_id) { seen = [payment.id, rev_id] }) do
        HandlePayoutReversedWorker.new.perform(@payment.id, @reversing_payout_id, @stripe_account_id)
      end
      assert_equal [@payment.id, @reversing_payout_id], seen
    end
  end

  test "does nothing when reversing payout failed" do
    Stripe::Payout.stub(:retrieve, ->(_args, _opts) { reversing_payout(payout_status: "failed", balance_transaction_status: "available") }) do
      called = false
      StripePayoutProcessor.stub(:handle_stripe_event_payout_reversed, ->(_p, _r) { called = true }) do
        HandlePayoutReversedWorker.new.perform(@payment.id, @reversing_payout_id, @stripe_account_id)
      end
      refute called
    end
  end

  test "raises when reversing payout isn't finalized" do
    Stripe::Payout.stub(:retrieve, ->(_args, _opts) { reversing_payout(payout_status: "paid", balance_transaction_status: "pending") }) do
      err = assert_raises(RuntimeError) { HandlePayoutReversedWorker.new.perform(@payment.id, @reversing_payout_id, @stripe_account_id) }
      assert_match(/Timed out waiting for reversing payout to become finalized/, err.message)
    end
  end
end
