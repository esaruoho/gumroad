# frozen_string_literal: true

require "test_helper"

class StripeTransferInternallyToCreatorTest < ActiveSupport::TestCase
  def fake_transfer
    Stripe::Transfer.construct_from(
      id: "tr_test",
      balance_transaction: Stripe::BalanceTransaction.construct_from(id: "txn_test")
    )
  end

  def assert_create_args(expected_subset)
    received = nil
    fake_create = lambda do |args|
      received = args
      fake_transfer
    end
    Stripe::Transfer.stub :create, fake_create do
      yield
    end
    expected_subset.each do |k, v|
      assert_equal v, received[k], "expected create arg #{k.inspect} to be #{v.inspect}, got #{received[k].inspect}"
    end
  end

  test "creates a transfer destined for the connected account with no related charge" do
    assert_create_args(
      destination: "acct_1",
      currency: "usd",
      amount: 1_000_00,
      description: "message_why",
      metadata: nil
    ) do
      StripeTransferInternallyToCreator.transfer_funds_to_account(
        message_why: "message_why",
        stripe_account_id: "acct_1",
        currency: Currency::USD,
        amount_cents: 1_000_00
      )
    end
  end

  test "returns a transfer with a balance transaction" do
    Stripe::Transfer.stub :create, ->(_args) { fake_transfer } do
      transfer = StripeTransferInternallyToCreator.transfer_funds_to_account(
        message_why: "message_why",
        stripe_account_id: "acct_1",
        currency: Currency::USD,
        amount_cents: 1_000_00
      )
      assert_kind_of Stripe::BalanceTransaction, transfer.balance_transaction
    end
  end

  test "creates a transfer with related charge id appended to description" do
    assert_create_args(
      destination: "acct_1",
      currency: "usd",
      amount: 1_000_00,
      description: "message_why Related Charge ID: charge-id.",
      metadata: nil
    ) do
      StripeTransferInternallyToCreator.transfer_funds_to_account(
        message_why: "message_why",
        stripe_account_id: "acct_1",
        currency: Currency::USD,
        amount_cents: 1_000_00,
        related_charge_id: "charge-id"
      )
    end
  end

  test "creates a transfer with the given metadata" do
    metadata = {
      metadata_1: "metadata_1",
      metadata_2: 1234,
      metadata_3: "metadata_2_a,metadata_2_a"
    }
    assert_create_args(
      destination: "acct_1",
      currency: "usd",
      amount: 1_000_00,
      description: "message_why",
      metadata: metadata
    ) do
      StripeTransferInternallyToCreator.transfer_funds_to_account(
        message_why: "message_why",
        stripe_account_id: "acct_1",
        currency: Currency::USD,
        amount_cents: 1_000_00,
        metadata: metadata
      )
    end
  end
end
