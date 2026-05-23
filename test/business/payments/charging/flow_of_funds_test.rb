# frozen_string_literal: true

require "test_helper"

class FlowOfFundsTest < ActiveSupport::TestCase
  setup do
    @currency = Currency::USD
    @amount_cents = 100_00
    @flow_of_funds = FlowOfFunds.build_simple_flow_of_funds(@currency, @amount_cents)
  end

  test "returns a FlowOfFunds object" do
    assert_kind_of FlowOfFunds, @flow_of_funds
  end

  test "has the issued amount" do
    assert_equal @currency, @flow_of_funds.issued_amount.currency
    assert_equal @amount_cents, @flow_of_funds.issued_amount.cents
  end

  test "has the settled amount" do
    assert_equal @currency, @flow_of_funds.settled_amount.currency
    assert_equal @amount_cents, @flow_of_funds.settled_amount.cents
  end

  test "has the gumroad amount" do
    assert_equal @currency, @flow_of_funds.gumroad_amount.currency
    assert_equal @amount_cents, @flow_of_funds.gumroad_amount.cents
  end

  test "has no merchant account gross/net amount" do
    assert_nil @flow_of_funds.merchant_account_gross_amount
    assert_nil @flow_of_funds.merchant_account_net_amount
  end
end
