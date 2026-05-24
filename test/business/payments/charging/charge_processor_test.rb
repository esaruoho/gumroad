# frozen_string_literal: true

require "test_helper"

class ChargeProcessorTest < ActiveSupport::TestCase
  # Test double for a Stripe chargeable — never actually called, but
  # has to respond to is_a?(...) in some paths.
  class FakeStripeChargeable
  end

  # Records the arguments passed to the wrapped method and returns
  # a stub value. Used to capture delegation arguments.
  class CallRecorder
    attr_reader :calls

    def initialize(return_value: nil)
      @return_value = return_value
      @calls = []
    end

    def call(*args, **kwargs)
      @calls << [args, kwargs]
      @return_value
    end
  end

  # Helper: stub one instance method on StripeChargeProcessor for the
  # duration of a block, restore the original after.
  def with_stripe_method(name, recorder)
    klass = StripeChargeProcessor
    if klass.method_defined?(name) || klass.private_method_defined?(name)
      original = klass.instance_method(name)
    end
    klass.define_method(name) do |*args, **kwargs|
      recorder.call(*args, **kwargs)
    end
    yield
  ensure
    klass.remove_method(name) if klass.method_defined?(name) || klass.private_method_defined?(name)
    klass.define_method(name, original) if original
  end

  test ".get_chargeable_for_params delegates to a Stripe processor" do
    rec = CallRecorder.new
    with_stripe_method(:get_chargeable_for_params, rec) do
      ChargeProcessor.get_chargeable_for_params({ param: "param" }, nil)
    end
    assert_equal 1, rec.calls.length
    args, _kwargs = rec.calls.first
    assert_equal [{ param: "param" }, nil], args
  end

  test ".get_chargeable_for_data delegates to the Stripe processor" do
    fake_stripe_chargeable = Object.new
    fake_stripe_chargeable.define_singleton_method(:charge_processor_id) { "stripe" }
    rec = CallRecorder.new(return_value: fake_stripe_chargeable)
    with_stripe_method(:get_chargeable_for_data, rec) do
      ChargeProcessor.get_chargeable_for_data(
        { StripeChargeProcessor.charge_processor_id => "customer-id" },
        "payment_method",
        "fingerprint",
        nil, nil,
        "4242", 16, "**** **** **** 4242",
        1, 2015, CardType::VISA, "US"
      )
    end
    assert_equal 1, rec.calls.length
    args, kwargs = rec.calls.first
    assert_equal [
      "customer-id", "payment_method", "fingerprint", nil, nil,
      "4242", 16, "**** **** **** 4242", 1, 2015, CardType::VISA, "US", nil
    ], args
    assert_equal({ merchant_account: nil }, kwargs)
  end

  test ".get_chargeable_for_data forwards optional zip when present" do
    fake_stripe_chargeable = Object.new
    fake_stripe_chargeable.define_singleton_method(:charge_processor_id) { "stripe" }
    rec = CallRecorder.new(return_value: fake_stripe_chargeable)
    with_stripe_method(:get_chargeable_for_data, rec) do
      ChargeProcessor.get_chargeable_for_data(
        { StripeChargeProcessor.charge_processor_id => "customer-id" },
        "payment_method", "fingerprint", nil, nil,
        "4242", 16, "**** **** **** 4242", 1, 2015, CardType::VISA, "US", "zip-code"
      )
    end
    args, _kwargs = rec.calls.first
    assert_equal "zip-code", args.last
  end

  test ".get_charge delegates to the Stripe processor" do
    rec = CallRecorder.new
    with_stripe_method(:get_charge, rec) do
      ChargeProcessor.get_charge(StripeChargeProcessor.charge_processor_id, "charge-id")
    end
    args, kwargs = rec.calls.first
    assert_equal ["charge-id"], args
    assert_equal({ merchant_account: nil }, kwargs)
  end

  test ".create_payment_intent_or_charge! delegates with statement_description and defaults" do
    rec = CallRecorder.new
    merchant_account = merchant_accounts(:forfeit_user_stripe_account)
    stripe_chargeable = FakeStripeChargeable.new
    chargeable = Object.new
    chargeable.define_singleton_method(:get_chargeable_for) { |_id| stripe_chargeable }

    with_stripe_method(:create_payment_intent_or_charge!, rec) do
      ChargeProcessor.create_payment_intent_or_charge!(
        merchant_account, chargeable, 1_00, 0_30, "reference", "description",
        statement_description: "statement-description", off_session: true, setup_future_charges: true
      )
    end
    args, kwargs = rec.calls.first
    assert_equal [merchant_account, stripe_chargeable, 1_00, 0_30, "reference", "description"], args
    assert_equal({
      metadata: nil, statement_description: "statement-description",
      transfer_group: nil, off_session: true,
      setup_future_charges: true, mandate_options: nil
    }, kwargs)
  end

  test ".create_payment_intent_or_charge! passes mandate_options through" do
    rec = CallRecorder.new
    merchant_account = merchant_accounts(:forfeit_user_stripe_account)
    stripe_chargeable = FakeStripeChargeable.new
    chargeable = Object.new
    chargeable.define_singleton_method(:get_chargeable_for) { |_id| stripe_chargeable }
    mandate_options = { payment_method_options: { card: { mandate_options: { reference: "ref" } } } }

    with_stripe_method(:create_payment_intent_or_charge!, rec) do
      ChargeProcessor.create_payment_intent_or_charge!(
        merchant_account, chargeable, 1_00, 0_30, "reference", "description",
        statement_description: "stmt", off_session: true,
        setup_future_charges: true, mandate_options: mandate_options
      )
    end
    _args, kwargs = rec.calls.first
    assert_equal mandate_options, kwargs[:mandate_options]
  end

  test ".get_charge_intent returns nil for blank intent id" do
    rec = CallRecorder.new
    merchant_account = merchant_accounts(:forfeit_user_stripe_account)
    with_stripe_method(:get_charge_intent, rec) do
      assert_nil ChargeProcessor.get_charge_intent(merchant_account, nil)
    end
    assert_equal 0, rec.calls.length
  end

  test ".get_charge_intent delegates to Stripe processor for present id" do
    rec = CallRecorder.new
    merchant_account = merchant_accounts(:forfeit_user_stripe_account)
    with_stripe_method(:get_charge_intent, rec) do
      ChargeProcessor.get_charge_intent(merchant_account, "pi_123456")
    end
    args, kwargs = rec.calls.first
    assert_equal ["pi_123456"], args
    assert_equal merchant_account, kwargs[:merchant_account]
  end

  test ".get_setup_intent returns nil for blank intent id" do
    rec = CallRecorder.new
    merchant_account = merchant_accounts(:forfeit_user_stripe_account)
    with_stripe_method(:get_setup_intent, rec) do
      assert_nil ChargeProcessor.get_setup_intent(merchant_account, nil)
    end
    assert_equal 0, rec.calls.length
  end

  test ".get_setup_intent delegates to Stripe processor for present id" do
    rec = CallRecorder.new
    merchant_account = merchant_accounts(:forfeit_user_stripe_account)
    with_stripe_method(:get_setup_intent, rec) do
      ChargeProcessor.get_setup_intent(merchant_account, "seti_123456")
    end
    args, kwargs = rec.calls.first
    assert_equal ["seti_123456"], args
    assert_equal merchant_account, kwargs[:merchant_account]
  end

  test ".confirm_payment_intent! delegates" do
    rec = CallRecorder.new
    merchant_account = merchant_accounts(:forfeit_user_stripe_account)
    with_stripe_method(:confirm_payment_intent!, rec) do
      ChargeProcessor.confirm_payment_intent!(merchant_account, "pi_123456")
    end
    args, _ = rec.calls.first
    assert_equal [merchant_account, "pi_123456"], args
  end

  test ".cancel_payment_intent! delegates" do
    rec = CallRecorder.new
    merchant_account = merchant_accounts(:forfeit_user_stripe_account)
    with_stripe_method(:cancel_payment_intent!, rec) do
      ChargeProcessor.cancel_payment_intent!(merchant_account, "pi_123456")
    end
    args, _ = rec.calls.first
    assert_equal [merchant_account, "pi_123456"], args
  end

  test ".cancel_setup_intent! delegates" do
    rec = CallRecorder.new
    merchant_account = merchant_accounts(:forfeit_user_stripe_account)
    with_stripe_method(:cancel_setup_intent!, rec) do
      ChargeProcessor.cancel_setup_intent!(merchant_account, "seti_123456")
    end
    args, _ = rec.calls.first
    assert_equal [merchant_account, "seti_123456"], args
  end

  test ".setup_future_charges! delegates with default nil mandate_options" do
    rec = CallRecorder.new
    merchant_account = merchant_accounts(:forfeit_user_stripe_account)
    stripe_chargeable = FakeStripeChargeable.new
    chargeable = Object.new
    chargeable.define_singleton_method(:get_chargeable_for) { |_id| stripe_chargeable }
    with_stripe_method(:setup_future_charges!, rec) do
      ChargeProcessor.setup_future_charges!(merchant_account, chargeable)
    end
    args, kwargs = rec.calls.first
    assert_equal [merchant_account, stripe_chargeable], args
    assert_equal({ mandate_options: nil }, kwargs)
  end

  test ".setup_future_charges! passes mandate_options" do
    rec = CallRecorder.new
    merchant_account = merchant_accounts(:forfeit_user_stripe_account)
    stripe_chargeable = FakeStripeChargeable.new
    chargeable = Object.new
    chargeable.define_singleton_method(:get_chargeable_for) { |_id| stripe_chargeable }
    mandate_options = { foo: "bar" }
    with_stripe_method(:setup_future_charges!, rec) do
      ChargeProcessor.setup_future_charges!(merchant_account, chargeable, mandate_options: mandate_options)
    end
    _args, kwargs = rec.calls.first
    assert_equal mandate_options, kwargs[:mandate_options]
  end

  test ".refund! delegates full refund to Stripe" do
    rec = CallRecorder.new
    with_stripe_method(:refund!, rec) do
      ChargeProcessor.refund!(StripeChargeProcessor.charge_processor_id, "charge-id")
    end
    args, kwargs = rec.calls.first
    assert_equal ["charge-id"], args
    assert_nil kwargs[:amount_cents]
    assert_equal true, kwargs[:reverse_transfer]
  end

  test ".refund! delegates partial refund to Stripe" do
    rec = CallRecorder.new
    with_stripe_method(:refund!, rec) do
      ChargeProcessor.refund!(StripeChargeProcessor.charge_processor_id, "charge-id", amount_cents: 2_00)
    end
    _args, kwargs = rec.calls.first
    assert_equal 2_00, kwargs[:amount_cents]
  end

  test ".holder_of_funds delegates" do
    rec = CallRecorder.new(return_value: :some_holder)
    merchant_account = merchant_accounts(:forfeit_user_stripe_account)
    with_stripe_method(:holder_of_funds, rec) do
      assert_equal :some_holder, ChargeProcessor.holder_of_funds(merchant_account)
    end
    args, _ = rec.calls.first
    assert_equal [merchant_account], args
  end

  test ".handle_event posts charge event to ActiveSupport::Notifications" do
    charge_event = ChargeEvent.new
    charge_event.type = ChargeEvent::TYPE_INFORMATIONAL
    charge_event.charge_event_id = "evt_test"
    received_payload = nil
    subscriber = ActiveSupport::Notifications.subscribe(ChargeProcessor::NOTIFICATION_CHARGE_EVENT) do |_, _, _, _, payload|
      received_payload = payload
    end
    begin
      ChargeProcessor.handle_event(charge_event)
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
    assert_equal charge_event, received_payload[:charge_event]
  end

  test ".transaction_url returns a String URI per processor in non-prod" do
    ChargeProcessor.charge_processor_ids.each do |cp_id|
      url = ChargeProcessor.transaction_url(cp_id, "dummy_charge_id")
      assert_kind_of String, url
      assert_kind_of URI::Generic, URI.parse(url)
    end
  end

  test ".transaction_url returns a String URI per processor in prod" do
    original = Rails.env
    Rails.singleton_class.send(:define_method, :env) { ActiveSupport::StringInquirer.new("production") }
    begin
      ChargeProcessor.charge_processor_ids.each do |cp_id|
        url = ChargeProcessor.transaction_url(cp_id, "dummy_charge_id")
        assert_kind_of String, url
        assert_kind_of URI::Generic, URI.parse(url)
      end
    ensure
      Rails.singleton_class.send(:define_method, :env) { original }
    end
  end

  test ".transaction_url_for_seller returns nil for missing inputs" do
    cp_id = StripeChargeProcessor.charge_processor_id
    assert_nil ChargeProcessor.transaction_url_for_seller(nil, "ch", false)
    assert_nil ChargeProcessor.transaction_url_for_seller(cp_id, nil, false)
    assert_nil ChargeProcessor.transaction_url_for_seller(cp_id, "ch", true)
  end

  test ".transaction_url_for_seller returns URL when seller-owned charge" do
    url = ChargeProcessor.transaction_url_for_seller(StripeChargeProcessor.charge_processor_id, "ch", false)
    assert_kind_of URI::Generic, URI.parse(url)
  end

  test ".transaction_url_for_admin returns nil for missing inputs" do
    cp_id = StripeChargeProcessor.charge_processor_id
    assert_nil ChargeProcessor.transaction_url_for_admin(nil, "ch", false)
    assert_nil ChargeProcessor.transaction_url_for_admin(cp_id, nil, false)
    assert_nil ChargeProcessor.transaction_url_for_admin(cp_id, "ch", false)
  end

  test ".transaction_url_for_admin returns URL for Gumroad-owned charge" do
    url = ChargeProcessor.transaction_url_for_admin(StripeChargeProcessor.charge_processor_id, "ch", true)
    assert_kind_of URI::Generic, URI.parse(url)
  end
end
