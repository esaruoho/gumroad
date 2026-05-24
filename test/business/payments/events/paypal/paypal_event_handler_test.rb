# frozen_string_literal: true

require "test_helper"

class PaypalEventHandlerTest < ActiveSupport::TestCase
  # Avoid singleton_class.prepend; restore in teardown.
  def stub_class_method(klass, name, &fake)
    @stubbed ||= []
    original = klass.respond_to?(name) ? klass.method(name) : nil
    klass.define_singleton_method(name, &fake)
    @stubbed << [klass, name, original]
  end

  def stub_instance_method(klass, name, &fake)
    @inst_stubbed ||= []
    original = klass.instance_method(name) if klass.method_defined?(name) || klass.private_method_defined?(name)
    klass.define_method(name, &fake)
    @inst_stubbed << [klass, name, original]
  end

  teardown do
    Array(@stubbed).reverse_each do |klass, name, original|
      if original
        klass.define_singleton_method(name, original)
      else
        klass.singleton_class.send(:remove_method, name) if klass.singleton_class.method_defined?(name) || klass.singleton_class.private_method_defined?(name)
      end
    end
    Array(@inst_stubbed).reverse_each do |klass, name, original|
      klass.send(:remove_method, name) if klass.method_defined?(name) || klass.private_method_defined?(name)
      klass.define_method(name, original) if original
    end
    @stubbed = nil
    @inst_stubbed = nil
  end

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

  # ---------------- #schedule_paypal_event_processing ---------------------

  test "schedules HandlePaypalEventWorker immediately for ORDER_API_EVENTS" do
    PaypalEventType::ORDER_API_EVENTS.each do |event_type|
      event_info = { "event_type" => event_type }
      Sidekiq::Testing.fake! do
        HandlePaypalEventWorker.jobs.clear
        PaypalEventHandler.new(event_info).schedule_paypal_event_processing
        assert_equal 1, HandlePaypalEventWorker.jobs.length, "expected immediate enqueue for #{event_type}"
        assert_equal [event_info], HandlePaypalEventWorker.jobs.first["args"]
        # `perform_async` does not set "at"
        assert_nil HandlePaypalEventWorker.jobs.first["at"]
      end
    end
  end

  test "schedules HandlePaypalEventWorker immediately for MERCHANT_ACCOUNT_EVENTS" do
    PaypalEventType::MERCHANT_ACCOUNT_EVENTS.each do |event_type|
      event_info = { "event_type" => event_type }
      Sidekiq::Testing.fake! do
        HandlePaypalEventWorker.jobs.clear
        PaypalEventHandler.new(event_info).schedule_paypal_event_processing
        assert_equal 1, HandlePaypalEventWorker.jobs.length, "expected immediate enqueue for #{event_type}"
        assert_equal [event_info], HandlePaypalEventWorker.jobs.first["args"]
        assert_nil HandlePaypalEventWorker.jobs.first["at"]
      end
    end
  end

  test "schedules HandlePaypalEventWorker after 10 minutes for legacy (e.g. masspay) events" do
    event_info = { "txn_type" => "masspay" }
    Sidekiq::Testing.fake! do
      HandlePaypalEventWorker.jobs.clear
      freeze_time = Time.current
      Time.stub(:current, freeze_time) do
        PaypalEventHandler.new(event_info).schedule_paypal_event_processing
      end
      assert_equal 1, HandlePaypalEventWorker.jobs.length
      assert_equal [event_info], HandlePaypalEventWorker.jobs.first["args"]
      assert_in_delta (freeze_time + 10.minutes).to_f, HandlePaypalEventWorker.jobs.first["at"].to_f, 1.0
    end
  end

  # ---------------- #handle_paypal_event: merchant account events ---------

  test "merchant account event is delegated to PaypalMerchantAccountManager#handle_paypal_event" do
    event_info = { "event_type" => PaypalEventType::MERCHANT_PARTNER_CONSENT_REVOKED }

    rec = CallRecorder.new
    stub_instance_method(PaypalMerchantAccountManager, :handle_paypal_event) { |*a, **k| rec.call(*a, **k) }

    PaypalEventHandler.new(event_info).handle_paypal_event

    assert_equal 1, rec.calls.length
    assert_equal [event_info], rec.calls.first.first
  end

  # ---------------- #handle_paypal_event: legacy IPN events ---------------

  def stub_ipn(body)
    WebMock.stub_request(:post, PAYPAL_IPN_VERIFICATION_URL).to_return(body: body)
  end

  # Reversal IPNs route to PaypalChargeProcessor
  test "reversal IPN is handled by PaypalChargeProcessor" do
    stub_ipn("VERIFIED")
    raw_payload = "payment_type=echeck&payment_status=Reversed&txn_type=web_accept&txn_id=995288809&" \
                  "parent_txn_id=SOMEPRIORTXNID002&reason_code=chargeback&invoice=dPFcxp0U0xmL5o0TD1NP9g%3D%3D&test_ipn=1"
    payload = Rack::Utils.parse_nested_query(raw_payload)

    payout_rec = CallRecorder.new
    charge_rec = CallRecorder.new
    stub_class_method(PaypalPayoutProcessor, :handle_paypal_event) { |*a, **k| payout_rec.call(*a, **k) }
    stub_class_method(PaypalChargeProcessor, :handle_paypal_event) { |*a, **k| charge_rec.call(*a, **k) }

    PaypalEventHandler.new(payload).handle_paypal_event

    assert_equal 0, payout_rec.calls.length
    assert_equal 1, charge_rec.calls.length
    assert_equal payload, charge_rec.calls.first.first.first
  end

  test "canceled reversal IPN is handled by PaypalChargeProcessor" do
    stub_ipn("VERIFIED")
    raw_payload = "payment_type=instant&payment_status=Canceled_Reversal&txn_type=web_accept&txn_id=694541630&" \
                  "parent_txn_id=SOMEPRIORTXNID003&reason_code=other&invoice=D7lNKK8L-urz8D3awchsUA%3D%3D&test_ipn=1"
    payload = Rack::Utils.parse_nested_query(raw_payload)

    payout_rec = CallRecorder.new
    charge_rec = CallRecorder.new
    stub_class_method(PaypalPayoutProcessor, :handle_paypal_event) { |*a, **k| payout_rec.call(*a, **k) }
    stub_class_method(PaypalChargeProcessor, :handle_paypal_event) { |*a, **k| charge_rec.call(*a, **k) }

    PaypalEventHandler.new(payload).handle_paypal_event

    assert_equal 0, payout_rec.calls.length
    assert_equal 1, charge_rec.calls.length
  end

  test "purchase IPN with invoice field is handled by PaypalChargeProcessor (not PaypalPayoutProcessor)" do
    stub_ipn("VERIFIED")
    raw_payload = "payment_type=instant&payment_status=Completed&txn_type=cart&txn_id=108864103&" \
                  "invoice=random_external_id%3D%3D&test_ipn=1"
    payload = Rack::Utils.parse_nested_query(raw_payload)

    payout_rec = CallRecorder.new
    charge_rec = CallRecorder.new
    stub_class_method(PaypalPayoutProcessor, :handle_paypal_event) { |*a, **k| payout_rec.call(*a, **k) }
    stub_class_method(PaypalChargeProcessor, :handle_paypal_event) { |*a, **k| charge_rec.call(*a, **k) }

    PaypalEventHandler.new(payload).handle_paypal_event

    assert_equal 0, payout_rec.calls.length
    assert_equal 1, charge_rec.calls.length
    assert_equal payload, charge_rec.calls.first.first.first
  end

  test "masspay IPN is handled by PaypalPayoutProcessor" do
    stub_ipn("VERIFIED")
    raw_payload = "txn_type=masspay&payment_status=Processed&masspay_txn_id_1=8G377690596809442&" \
                  "ipn_track_id=29339dfb40e24"
    payload = Rack::Utils.parse_nested_query(raw_payload)

    payout_rec = CallRecorder.new
    charge_rec = CallRecorder.new
    stub_class_method(PaypalPayoutProcessor, :handle_paypal_event) { |*a, **k| payout_rec.call(*a, **k) }
    stub_class_method(PaypalChargeProcessor, :handle_paypal_event) { |*a, **k| charge_rec.call(*a, **k) }

    PaypalEventHandler.new(payload).handle_paypal_event

    assert_equal 1, payout_rec.calls.length
    assert_equal payload, payout_rec.calls.first.first.first
    assert_equal 0, charge_rec.calls.length
  end

  # Ignored IPN message types
  %w[cart express_checkout mp_signup].each do |txn_type|
    test "ignored IPN txn_type=#{txn_type} does not route to any handler and does not error" do
      stub_ipn("VERIFIED")
      payload = Rack::Utils.parse_nested_query("txn_type=#{txn_type}&item_name=Gumroad+Purchase")

      payout_rec = CallRecorder.new
      charge_rec = CallRecorder.new
      notifier_rec = CallRecorder.new
      stub_class_method(PaypalPayoutProcessor, :handle_paypal_event) { |*a, **k| payout_rec.call(*a, **k) }
      stub_class_method(PaypalChargeProcessor, :handle_paypal_event) { |*a, **k| charge_rec.call(*a, **k) }
      stub_class_method(ErrorNotifier, :notify) { |*a, **k| notifier_rec.call(*a, **k) }

      assert_nothing_raised { PaypalEventHandler.new(payload).handle_paypal_event }
      assert_equal 0, payout_rec.calls.length
      assert_equal 0, charge_rec.calls.length
      assert_equal 0, notifier_rec.calls.length
    end
  end

  test "IPN with invalid (INVALID) verification does not route to PaypalPayoutProcessor" do
    stub_ipn("INVALID")
    raw_payload = "txn_type=masspay&payment_status=Processed&masspay_txn_id_1=8G377690596809442"
    payload = Rack::Utils.parse_nested_query(raw_payload)

    payout_rec = CallRecorder.new
    stub_class_method(PaypalPayoutProcessor, :handle_paypal_event) { |*a, **k| payout_rec.call(*a, **k) }

    PaypalEventHandler.new(payload).handle_paypal_event

    assert_equal 0, payout_rec.calls.length
  end
end
