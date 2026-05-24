# frozen_string_literal: true

require "test_helper"

class BraintreeChargeRefundTest < ActiveSupport::TestCase
  setup do
    @braintree_refund_transaction = Struct.new(:id, :refunded_transaction_id, :amount).new(
      "refund_abc123",
      "original_charge_xyz",
      100.00
    )
  end

  test "#charge_processor_id is braintree" do
    refund = BraintreeChargeRefund.new(@braintree_refund_transaction)
    assert_equal "braintree", refund.charge_processor_id
  end

  test "#id comes from the braintree refund transaction" do
    refund = BraintreeChargeRefund.new(@braintree_refund_transaction)
    assert_equal "refund_abc123", refund.id
  end

  test "#charge_id is the refunded_transaction_id" do
    refund = BraintreeChargeRefund.new(@braintree_refund_transaction)
    assert_equal "original_charge_xyz", refund.charge_id
  end

  test "#flow_of_funds is a simple negative USD flow of funds" do
    refund = BraintreeChargeRefund.new(@braintree_refund_transaction)
    fof = refund.flow_of_funds

    assert_equal Currency::USD, fof.issued_amount.currency
    assert_equal(-100_00, fof.issued_amount.cents)
    assert_equal Currency::USD, fof.settled_amount.currency
    assert_equal(-100_00, fof.settled_amount.cents)
    assert_equal Currency::USD, fof.gumroad_amount.currency
    assert_equal(-100_00, fof.gumroad_amount.cents)
    assert_nil fof.merchant_account_gross_amount
    assert_nil fof.merchant_account_net_amount
  end
end
