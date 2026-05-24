# frozen_string_literal: true

require "test_helper"

class PaypalChargeRefundTest < ActiveSupport::TestCase
  test "with a paypal refund response, has charge_processor_id 'paypal', id, charge_id, and nil flow_of_funds" do
    pre_prepared_paypal_charge_id = "58409660Y47347418"
    refund_response = Struct.new(:RefundTransactionID).new("ABC123REFUND")

    subject = PaypalChargeRefund.new(refund_response, pre_prepared_paypal_charge_id)

    assert_equal "paypal", subject.charge_processor_id
    assert_equal "ABC123REFUND", subject.id
    assert_equal pre_prepared_paypal_charge_id, subject.charge_id
    assert_nil subject.flow_of_funds
  end
end
