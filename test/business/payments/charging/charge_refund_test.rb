# frozen_string_literal: true

require "test_helper"

class ChargeRefundTest < ActiveSupport::TestCase
  setup do
    @flow_of_funds = FlowOfFunds.build_simple_flow_of_funds(Currency::USD, 1_00)
    @charge_refund = ChargeRefund.new
    @charge_refund.flow_of_funds = @flow_of_funds
  end

  test "#flow_of_funds is present" do
    assert_predicate @charge_refund.flow_of_funds, :present?
  end

  test "#flow_of_funds has an issued amount" do
    assert_predicate @charge_refund.flow_of_funds.issued_amount, :present?
  end

  test "#flow_of_funds has a settled amount" do
    assert_predicate @charge_refund.flow_of_funds.settled_amount, :present?
  end

  test "#flow_of_funds has a gumroad amount" do
    assert_predicate @charge_refund.flow_of_funds.gumroad_amount, :present?
  end
end
