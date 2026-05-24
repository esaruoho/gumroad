# frozen_string_literal: true

require "test_helper"

class StripeChargeRefundTest < ActiveSupport::TestCase
  CURRENCY = Currency::USD
  AMOUNT_CENTS = 1_00
  DESTINATION_CURRENCY = Currency::CAD
  APPLICATION_FEE = 50

  def simple_refund_args
    charge = OpenStruct.new(id: "ch_simple", amount: AMOUNT_CENTS, currency: CURRENCY, destination: nil,
                            application_fee: nil, on_behalf_of: nil)
    charge[:destination] = nil
    refund = { id: "re_simple", charge: "ch_simple", amount: AMOUNT_CENTS, currency: CURRENCY }
    bt = { id: "bt_simple", currency: CURRENCY, amount: -AMOUNT_CENTS }
    [charge, refund, nil, bt, nil, nil, nil]
  end

  test "initialize with simple stripe refund sets charge_processor_id 'stripe', id, charge_id" do
    args = simple_refund_args
    subject = StripeChargeRefund.new(*args)
    assert_equal "stripe", subject.charge_processor_id
    assert_equal "re_simple", subject.id
    assert_equal "ch_simple", subject.charge_id
  end

  # --- With destination, refund involves destination (reverse_transfer + refund_application_fee) ---

  def destination_refund_args(amount: AMOUNT_CENTS, with_destination: true)
    charge = OpenStruct.new(
      id: "ch_dst", amount: AMOUNT_CENTS, currency: CURRENCY,
      destination: with_destination ? "acct_dest" : nil,
      application_fee: nil, on_behalf_of: nil
    )
    charge[:destination] = with_destination ? "acct_dest" : nil
    refund = { id: "re_dst", charge: "ch_dst", amount: amount, currency: CURRENCY }
    bt = OpenStruct.new(id: "bt_dst", currency: CURRENCY, amount: -amount)
    bt[:currency] = CURRENCY
    bt[:amount] = -amount
    [charge, refund, bt]
  end

  test "flow_of_funds with destination involvement" do
    charge, refund, refund_bt = destination_refund_args

    destination_payment_refund = { id: "re_dp", amount: AMOUNT_CENTS - APPLICATION_FEE, currency: CURRENCY }
    dp_refund_bt = OpenStruct.new(id: "bt_dp", currency: DESTINATION_CURRENCY, amount: -(AMOUNT_CENTS - APPLICATION_FEE))
    dp_refund_bt[:currency] = DESTINATION_CURRENCY
    dp_refund_bt[:amount] = -(AMOUNT_CENTS - APPLICATION_FEE)
    app_fee_refund_bt = OpenStruct.new(id: "bt_afr", currency: CURRENCY, amount: -APPLICATION_FEE)
    app_fee_refund_bt[:currency] = CURRENCY
    app_fee_refund_bt[:amount] = -APPLICATION_FEE
    dest_app_fee_refund = OpenStruct.new(id: "afr_dest", currency: DESTINATION_CURRENCY, amount: 0)
    dest_app_fee_refund[:currency] = DESTINATION_CURRENCY
    dest_app_fee_refund[:amount] = 0

    subject = StripeChargeRefund.new(
      charge, refund, destination_payment_refund,
      refund_bt, app_fee_refund_bt, dp_refund_bt, dest_app_fee_refund
    )

    fof = subject.flow_of_funds
    assert_equal CURRENCY, fof.issued_amount.currency
    assert_equal(-AMOUNT_CENTS, fof.issued_amount.cents)

    assert_equal CURRENCY, fof.settled_amount.currency
    assert_equal refund_bt[:amount], fof.settled_amount.cents

    assert_equal CURRENCY, fof.gumroad_amount.currency
    # With destination + app fee refund, gumroad_amount comes from app_fee_refund_balance_transaction
    assert_equal app_fee_refund_bt[:amount], fof.gumroad_amount.cents

    assert_equal DESTINATION_CURRENCY, fof.merchant_account_gross_amount.currency
    assert_equal dp_refund_bt[:amount], fof.merchant_account_gross_amount.cents

    assert_equal DESTINATION_CURRENCY, fof.merchant_account_net_amount.currency
    # net amount = dp_refund_bt.amount + dest_app_fee_refund.amount
    assert_equal dp_refund_bt[:amount] + dest_app_fee_refund[:amount], fof.merchant_account_net_amount.cents
  end

  test "flow_of_funds without destination involvement (partial refund, no reverse_transfer)" do
    refunded_amount_cents = 30
    charge, refund, refund_bt = destination_refund_args(amount: refunded_amount_cents)
    # No destination_payment_refund_balance_transaction -> fof_has_destination? is false
    subject = StripeChargeRefund.new(
      charge, refund, nil,
      refund_bt, nil, nil, nil
    )

    fof = subject.flow_of_funds
    assert_equal CURRENCY, fof.issued_amount.currency
    assert_equal(-refunded_amount_cents, fof.issued_amount.cents)

    assert_equal CURRENCY, fof.settled_amount.currency
    assert_equal refund_bt[:amount], fof.settled_amount.cents

    # Falls through to the "else" branch (no application_fee account, no destination) -> gumroad = settled
    assert_equal CURRENCY, fof.gumroad_amount.currency
    assert_equal(-refund[:amount], fof.gumroad_amount.cents)

    assert_nil fof.merchant_account_gross_amount
    assert_nil fof.merchant_account_net_amount
  end
end
