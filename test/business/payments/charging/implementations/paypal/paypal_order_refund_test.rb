# frozen_string_literal: true

require "test_helper"

class PaypalOrderRefundTest < ActiveSupport::TestCase
  test ".new sets attributes correctly" do
    refund_response = Struct.new(:id).new("ExampleID")
    order_refund = PaypalOrderRefund.new(refund_response, "SampleCaptureId")
    assert_equal PaypalChargeProcessor.charge_processor_id, order_refund.charge_processor_id
    assert_equal "SampleCaptureId", order_refund.charge_id
    assert_equal "ExampleID", order_refund.id
  end
end
