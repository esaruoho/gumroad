# frozen_string_literal: true

require "test_helper"

class BaseProcessorChargeTest < ActiveSupport::TestCase
  setup do
    @flow_of_funds = FlowOfFunds.build_simple_flow_of_funds(Currency::USD, 1_00)
    @charge = BaseProcessorCharge.new
    @charge.flow_of_funds = @flow_of_funds
    @charge.id = "charge-id"
  end

  test "#[] gives access to getting attributes" do
    assert_equal "charge-id", @charge[:id]
  end

  test "#flow_of_funds is present" do
    assert_predicate @charge.flow_of_funds, :present?
  end

  test "#flow_of_funds has an issued amount" do
    assert_predicate @charge.flow_of_funds.issued_amount, :present?
  end

  test "#flow_of_funds has a settled amount" do
    assert_predicate @charge.flow_of_funds.settled_amount, :present?
  end

  test "#flow_of_funds has a gumroad amount" do
    assert_predicate @charge.flow_of_funds.gumroad_amount, :present?
  end
end
