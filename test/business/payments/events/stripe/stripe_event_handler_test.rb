# frozen_string_literal: true

require "test_helper"

class StripeEventHandlerTest < ActiveSupport::TestCase
  # ---- Helpers ----------------------------------------------------------

  class CallRecorder
    attr_reader :calls
    def initialize(return_value: nil, raise: nil)
      @return_value = return_value
      @raise_exc = raise
      @calls = []
    end
    def call(*args, **kwargs)
      @calls << [args, kwargs]
      raise @raise_exc if @raise_exc
      @return_value
    end
  end

  # Stash class-method overrides for the test; teardown restores them.
  # Avoids singleton_class.prepend per task rule.
  def stub_class_method(klass, name, &fake)
    @stubbed ||= []
    original = klass.respond_to?(name) ? klass.method(name) : nil
    klass.define_singleton_method(name, &fake)
    @stubbed << [klass, name, original]
  end

  teardown do
    Array(@stubbed).reverse_each do |klass, name, original|
      if original
        klass.define_singleton_method(name, original)
      else
        klass.singleton_class.send(:remove_method, name) if klass.singleton_class.method_defined?(name) || klass.singleton_class.private_method_defined?(name)
      end
    end
    @stubbed = nil
  end

  EVENT_ID = "evt_eventid"

  # ---- error handling ---------------------------------------------------

  test "silences errors when in staging environment" do
    Rails.env.stub(:staging?, true) do
      assert_nothing_raised do
        StripeEventHandler.new(id: "invalid-event-id").handle_stripe_event
      end
    end
  end

  test "does not silence errors when not in staging environment" do
    Rails.env.stub(:staging?, false) do
      assert_raises(NoMethodError) do
        StripeEventHandler.new(id: "invalid-event-id", type: "charge.succeeded").handle_stripe_event
      end
    end
  end

  # ---- Events on Gumroad's account --------------------------------------

  test "charge event on gumroad's account is sent to StripeChargeProcessor" do
    stripe_event = {
      "id" => EVENT_ID,
      "created" => "1406748559",
      "type" => "charge.succeeded",
      "data" => { "object" => { "object" => "charge" } }
    }

    rec = CallRecorder.new
    stub_class_method(StripeChargeProcessor, :handle_stripe_event) { |*a, **k| rec.call(*a, **k) }
    StripeEventHandler.new(stripe_event).handle_stripe_event

    assert_equal 1, rec.calls.length
    arg = rec.calls.first.first.first
    assert_equal "charge.succeeded", arg["type"]
    assert_equal EVENT_ID, arg["id"]
  end

  test "payment_intent.payment_failed event on gumroad's account is sent to StripeChargeProcessor" do
    stripe_event = {
      "id" => EVENT_ID,
      "created" => "1406748559",
      "type" => "payment_intent.payment_failed",
      "data" => { "object" => { "object" => "payment_intent" } }
    }
    rec = CallRecorder.new
    stub_class_method(StripeChargeProcessor, :handle_stripe_event) { |*a, **k| rec.call(*a, **k) }
    StripeEventHandler.new(stripe_event).handle_stripe_event
    assert_equal 1, rec.calls.length
    assert_equal "payment_intent.payment_failed", rec.calls.first.first.first["type"]
  end

  test "capital event on gumroad's account is sent to StripeChargeProcessor" do
    stripe_event = {
      "id" => EVENT_ID,
      "created" => "1668996442",
      "type" => "capital.financing_transaction.created",
      "data" => { "object" => { "object" => "capital.financing_transaction" } }
    }
    rec = CallRecorder.new
    stub_class_method(StripeChargeProcessor, :handle_stripe_event) { |*a, **k| rec.call(*a, **k) }
    StripeEventHandler.new(stripe_event).handle_stripe_event
    assert_equal 1, rec.calls.length
    assert_equal "capital.financing_transaction.created", rec.calls.first.first.first["type"]
  end

  test "account.updated event on gumroad's account is NOT sent to StripeMerchantAccountManager" do
    stripe_event = {
      "id" => EVENT_ID,
      "created" => "1406748559",
      "type" => "account.updated",
      "data" => { "object" => { "object" => "account" } }
    }
    rec = CallRecorder.new
    stub_class_method(StripeMerchantAccountManager, :handle_stripe_event) { |*a, **k| rec.call(*a, **k) }
    StripeEventHandler.new(stripe_event).handle_stripe_event
    assert_equal 0, rec.calls.length
  end

  test "ignored invoice.created event triggers no processors and does not retrieve from Stripe" do
    stripe_event = {
      "id" => EVENT_ID,
      "created" => "1406748559",
      "type" => "invoice.created",
      "data" => { "object" => { "object" => "invoice" } }
    }
    charge_rec = CallRecorder.new
    manager_rec = CallRecorder.new
    retrieve_rec = CallRecorder.new

    stub_class_method(StripeChargeProcessor, :handle_stripe_event) { |*a, **k| charge_rec.call(*a, **k) }
    stub_class_method(StripeMerchantAccountManager, :handle_stripe_event) { |*a, **k| manager_rec.call(*a, **k) }
    stub_class_method(Stripe::Event, :retrieve) { |*a, **k| retrieve_rec.call(*a, **k) }

    StripeEventHandler.new(stripe_event).handle_stripe_event

    assert_equal 0, charge_rec.calls.length
    assert_equal 0, manager_rec.calls.length
    assert_equal 0, retrieve_rec.calls.length
  end

  # ---- Events on a connected account ------------------------------------

  test "account.updated event on a connected account is sent to StripeMerchantAccountManager" do
    merchant_account = merchant_accounts(:radar_stripe_connect_account)
    stripe_event = {
      "id" => EVENT_ID,
      "created" => "1406748559",
      "type" => "account.updated",
      "account" => merchant_account.charge_processor_merchant_id,
      "user_id" => merchant_account.charge_processor_merchant_id,
      "default_currency" => "usd",
      "country" => "USA",
      "data" => {
        "object" => {
          "object" => "account",
          "default_currency" => "usd",
          "country" => "USA",
          "id" => merchant_account.charge_processor_merchant_id
        }
      }
    }

    charge_rec = CallRecorder.new
    manager_rec = CallRecorder.new
    stub_class_method(StripeChargeProcessor, :handle_stripe_event) { |*a, **k| charge_rec.call(*a, **k) }
    stub_class_method(StripeMerchantAccountManager, :handle_stripe_event) { |*a, **k| manager_rec.call(*a, **k) }

    StripeEventHandler.new(stripe_event).handle_stripe_event

    assert_equal 0, charge_rec.calls.length
    assert_equal 1, manager_rec.calls.length
  end

  test "payout event on a connected account is sent to StripePayoutProcessor with stripe_connect_account_id" do
    stripe_event = {
      "id" => EVENT_ID,
      "created" => "1406748559",
      "type" => "payout.paid",
      "account" => "acct_1234",
      "user_id" => "acct_1234",
      "data" => {
        "object" => {
          "object" => "transfer",
          "type" => "bank_account",
          "id" => "tr_1234"
        }
      }
    }

    charge_rec = CallRecorder.new
    manager_rec = CallRecorder.new
    payout_rec = CallRecorder.new
    stub_class_method(StripeChargeProcessor, :handle_stripe_event) { |*a, **k| charge_rec.call(*a, **k) }
    stub_class_method(StripeMerchantAccountManager, :handle_stripe_event) { |*a, **k| manager_rec.call(*a, **k) }
    stub_class_method(StripePayoutProcessor, :handle_stripe_event) { |*a, **k| payout_rec.call(*a, **k) }

    StripeEventHandler.new(stripe_event).handle_stripe_event

    assert_equal 0, charge_rec.calls.length
    assert_equal 0, manager_rec.calls.length
    assert_equal 1, payout_rec.calls.length
    args, kwargs = payout_rec.calls.first
    assert_equal "payout.paid", args.first["type"]
    assert_equal "acct_1234", kwargs[:stripe_connect_account_id]
  end

  test "account deauthorized: rescues Stripe::APIError-shaped error and routes to deauthorize handler" do
    merchant_account = merchant_accounts(:radar_stripe_connect_account)
    stripe_event = {
      "id" => EVENT_ID,
      "created" => "1406748559",
      "type" => "account.updated",
      "account" => merchant_account.charge_processor_merchant_id,
      "user_id" => merchant_account.charge_processor_merchant_id,
      "data" => {
        "object" => {
          "object" => "account",
          "id" => merchant_account.charge_processor_merchant_id
        }
      }
    }

    err = StandardError.new("Application access may have been revoked.")
    deauth_rec = CallRecorder.new
    stub_class_method(StripeMerchantAccountManager, :handle_stripe_event) { |*_a, **_k| raise err }
    stub_class_method(StripeMerchantAccountManager, :handle_stripe_event_account_deauthorized) { |*a, **k| deauth_rec.call(*a, **k) }

    assert_nothing_raised do
      StripeEventHandler.new(stripe_event).handle_stripe_event
    end
    assert_equal 1, deauth_rec.calls.length
    assert_equal "account.application.deauthorized", deauth_rec.calls.first.first.first["type"]
  end

  test "capability.updated event on a connected account is sent to StripeMerchantAccountManager" do
    merchant_account = merchant_accounts(:radar_stripe_connect_account)
    stripe_event = {
      "id" => EVENT_ID,
      "created" => "1668996442",
      "type" => "capability.updated",
      "account" => merchant_account.charge_processor_merchant_id,
      "user_id" => merchant_account.charge_processor_merchant_id,
      "data" => {
        "object" => {
          "object" => "capability",
          "id" => "transfers",
          "account" => merchant_account.charge_processor_merchant_id,
          "requirements" => {
            "currently_due" => ["individual.verification.document"]
          }
        }
      }
    }

    charge_rec = CallRecorder.new
    manager_rec = CallRecorder.new
    stub_class_method(StripeChargeProcessor, :handle_stripe_event) { |*a, **k| charge_rec.call(*a, **k) }
    stub_class_method(StripeMerchantAccountManager, :handle_stripe_event) { |*a, **k| manager_rec.call(*a, **k) }

    StripeEventHandler.new(stripe_event).handle_stripe_event

    assert_equal 0, charge_rec.calls.length
    assert_equal 1, manager_rec.calls.length
    assert_equal "capability.updated", manager_rec.calls.first.first.first["type"]
  end
end
