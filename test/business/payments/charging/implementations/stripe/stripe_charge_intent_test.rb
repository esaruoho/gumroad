# frozen_string_literal: true

require "test_helper"

class StripeChargeIntentTest < ActiveSupport::TestCase
  def build_pi(status:, next_action_type: nil, id: "pi_123", client_secret: "pi_123_secret", latest_charge: nil)
    next_action = next_action_type ? OpenStruct.new(type: next_action_type) : nil
    OpenStruct.new(
      id: id,
      client_secret: client_secret,
      status: status,
      next_action: next_action,
      latest_charge: latest_charge,
      charges: OpenStruct.new(first: nil)
    )
  end

  test "#id returns the ID of Stripe payment intent" do
    pi = build_pi(status: StripeIntentStatus::REQUIRES_CONFIRMATION)
    assert_equal "pi_123", StripeChargeIntent.new(payment_intent: pi).id
  end

  test "#client_secret returns the client secret" do
    pi = build_pi(status: StripeIntentStatus::REQUIRES_CONFIRMATION)
    assert_equal "pi_123_secret", StripeChargeIntent.new(payment_intent: pi).client_secret
  end

  test "when requires_confirmation: not successful, no charge load" do
    pi = build_pi(status: StripeIntentStatus::REQUIRES_CONFIRMATION)
    sci = StripeChargeIntent.new(payment_intent: pi)
    assert_equal false, sci.succeeded?
    assert_equal StripeIntentStatus::REQUIRES_CONFIRMATION, sci.payment_intent.status
    assert_nil sci.charge
  end

  test "when successful: succeeded?, not requires_action, loads charge" do
    pi = build_pi(status: StripeIntentStatus::SUCCESS, latest_charge: "ch_loaded")
    fake_charge = Object.new
    StripeChargeProcessor.class_eval do
      alias_method :__orig_get_charge, :get_charge
      define_method(:get_charge) { |id, **| fake_charge }
    end
    begin
      sci = StripeChargeIntent.new(payment_intent: pi)
      assert_equal true, sci.succeeded?
      assert_equal false, sci.requires_action?
      assert_equal fake_charge, sci.charge
    ensure
      StripeChargeProcessor.class_eval do
        remove_method :get_charge
        alias_method :get_charge, :__orig_get_charge
        remove_method :__orig_get_charge
      end
    end
  end

  test "when not successful (requires_payment_method): no charge, not action" do
    pi = build_pi(status: "requires_payment_method")
    sci = StripeChargeIntent.new(payment_intent: pi)
    assert_equal false, sci.succeeded?
    assert_equal false, sci.requires_action?
    assert_nil sci.charge
  end

  test "when canceled: canceled?, not succeeded, not requires_action, no charge" do
    pi = build_pi(status: StripeIntentStatus::CANCELED)
    sci = StripeChargeIntent.new(payment_intent: pi)
    assert_equal true, sci.canceled?
    assert_equal false, sci.succeeded?
    assert_equal false, sci.requires_action?
    assert_nil sci.charge
  end

  test "when requires_action with use_stripe_sdk: requires_action true, no charge" do
    pi = build_pi(status: StripeIntentStatus::REQUIRES_ACTION,
                  next_action_type: StripeIntentStatus::ACTION_TYPE_USE_SDK)
    sci = StripeChargeIntent.new(payment_intent: pi)
    assert_equal false, sci.succeeded?
    assert_equal true, sci.requires_action?
    assert_nil sci.charge
  end

  test "when next action type unsupported: notifies ErrorNotifier" do
    pi = build_pi(status: StripeIntentStatus::REQUIRES_ACTION, next_action_type: "redirect_to_url")
    notified = nil
    ErrorNotifier.stub(:notify, ->(msg) { notified = msg }) do
      StripeChargeIntent.new(payment_intent: pi)
    end
    assert_match(/requires an unsupported action/, notified.to_s)
  end
end
