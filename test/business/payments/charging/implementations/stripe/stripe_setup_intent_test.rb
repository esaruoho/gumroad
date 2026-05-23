# frozen_string_literal: true

require "test_helper"

class StripeSetupIntentTest < ActiveSupport::TestCase
  def build_setup_intent(status:, next_action_type: nil, id: "seti_123", client_secret: "seti_123_secret_xyz")
    next_action = next_action_type ? OpenStruct.new(type: next_action_type) : nil
    OpenStruct.new(id: id, client_secret: client_secret, status: status, next_action: next_action)
  end

  test "#id returns the ID of Stripe setup intent" do
    si = build_setup_intent(status: StripeIntentStatus::SUCCESS)
    assert_equal "seti_123", StripeSetupIntent.new(si).id
  end

  test "#client_secret returns the client secret of Stripe setup intent" do
    si = build_setup_intent(status: StripeIntentStatus::SUCCESS)
    assert_equal "seti_123_secret_xyz", StripeSetupIntent.new(si).client_secret
  end

  test "when successful, succeeded? is true and requires_action? is false" do
    s = StripeSetupIntent.new(build_setup_intent(status: StripeIntentStatus::SUCCESS))
    assert_equal true, s.succeeded?
    assert_equal false, s.requires_action?
  end

  test "when not successful (requires payment method), succeeded? false and requires_action? false" do
    s = StripeSetupIntent.new(build_setup_intent(status: "requires_payment_method"))
    assert_equal false, s.succeeded?
    assert_equal false, s.requires_action?
  end

  test "when canceled, canceled? true, succeeded? false, requires_action? false" do
    s = StripeSetupIntent.new(build_setup_intent(status: StripeIntentStatus::CANCELED))
    assert_equal true, s.canceled?
    assert_equal false, s.succeeded?
    assert_equal false, s.requires_action?
  end

  test "when requires_action with use_stripe_sdk, succeeded? false and requires_action? true" do
    s = StripeSetupIntent.new(build_setup_intent(
                                status: StripeIntentStatus::REQUIRES_ACTION,
                                next_action_type: StripeIntentStatus::ACTION_TYPE_USE_SDK
                              ))
    assert_equal false, s.succeeded?
    assert_equal true, s.requires_action?
  end

  test "when next action type is unsupported, notifies ErrorNotifier" do
    si = build_setup_intent(
      status: StripeIntentStatus::REQUIRES_ACTION,
      next_action_type: "redirect_to_url"
    )
    notified = nil
    ErrorNotifier.stub(:notify, ->(msg) { notified = msg }) do
      StripeSetupIntent.new(si)
    end
    assert_match(/requires an unsupported action/, notified.to_s)
  end
end
