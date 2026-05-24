# frozen_string_literal: true

require "test_helper"

class Order::ChargeServiceTest < ActiveSupport::TestCase
  test "initializer wires up order, params, and an empty charge_responses hash" do
    order = Order.new
    params = { perceived_price_cents: 1000 }

    service = Order::ChargeService.new(order: order, params: params)

    assert_equal order, service.order
    assert_equal params, service.params
    assert_equal({}, service.charge_responses)
    assert_nil service.charge_intent
    assert_nil service.setup_intent
  end

  test "charge_intent and setup_intent are writable accessors" do
    service = Order::ChargeService.new(order: Order.new, params: {})

    service.charge_intent = :sentinel_charge
    service.setup_intent = :sentinel_setup

    assert_equal :sentinel_charge, service.charge_intent
    assert_equal :sentinel_setup, service.setup_intent
  end

  # TODO: end-to-end charge flow (103 FactoryBot refs in original) exercises
  # the full Stripe SCA + multi-seller order pipeline with charge_intents,
  # setup_intents, payment_method save flows, and dispute outcomes — all
  # tested under VCR cassettes against stripe-mock. Out of scope for the
  # fixture-only Minitest lane. Original: spec/services/order/charge_service_spec.rb
end
