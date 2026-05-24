# frozen_string_literal: true

require "test_helper"

class HandleStripeAutodebitForNegativeBalanceTest < ActiveSupport::TestCase
  setup do
    @stripe_payout_id = "po_automatic"
    @stripe_connect_account_id = "acct_1234"
    @stripe_event_id = "evt_eventid"
  end

  def payout_obj(payout_status:, balance_transaction_status:)
    {
      "object" => "payout",
      "id" => "po_automatic",
      "automatic" => true,
      "amount" => -100_00,
      "currency" => "usd",
      "account" => @stripe_connect_account_id,
      "status" => payout_status,
      "balance_transaction" => { "status" => balance_transaction_status }
    }
  end

  test "calls StripePayoutProcessor.handle_stripe_negative_balance_debit_event when payout succeeds" do
    Stripe::Payout.stub(:retrieve, ->(_args, _opts) { payout_obj(payout_status: "paid", balance_transaction_status: "available") }) do
      seen = nil
      StripePayoutProcessor.stub(:handle_stripe_negative_balance_debit_event, ->(acct, po) { seen = [acct, po] }) do
        HandleStripeAutodebitForNegativeBalance.new.perform(@stripe_event_id, @stripe_connect_account_id, @stripe_payout_id)
      end
      assert_equal [@stripe_connect_account_id, @stripe_payout_id], seen
    end
  end

  test "does nothing when payout failed" do
    Stripe::Payout.stub(:retrieve, ->(_args, _opts) { payout_obj(payout_status: "failed", balance_transaction_status: "available") }) do
      called = false
      StripePayoutProcessor.stub(:handle_stripe_negative_balance_debit_event, ->(_a, _p) { called = true }) do
        HandleStripeAutodebitForNegativeBalance.new.perform(@stripe_event_id, @stripe_connect_account_id, @stripe_payout_id)
      end
      refute called
    end
  end

  test "raises when payout isn't finalized" do
    Stripe::Payout.stub(:retrieve, ->(_args, _opts) { payout_obj(payout_status: "paid", balance_transaction_status: "pending") }) do
      err = assert_raises(RuntimeError) { HandleStripeAutodebitForNegativeBalance.new.perform(@stripe_event_id, @stripe_connect_account_id, @stripe_payout_id) }
      assert_match(/Timed out waiting for payout to become finalized/, err.message)
    end
  end
end
