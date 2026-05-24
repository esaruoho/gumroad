# frozen_string_literal: true

require "test_helper"

class StripeChargeRadarProcessorTest < ActiveSupport::TestCase
  setup do
    @orig_api_base = Stripe.api_base
    Stripe.api_base = "http://127.0.0.1:12111"
    # update_from_stripe! calls Stripe::Radar::EarlyFraudWarning.retrieve(processor_id, expand: ["charge"]).
    # stripe-mock returns a generic radar.early_fraud_warning object that's good enough for the
    # `update_from_stripe!` write-side (it just copies a handful of fields).
  end

  teardown do
    Stripe.api_base = @orig_api_base
  end
  def stub_efw_retrieve(processor_id, charge_id: "ch_stub", risk_level: "elevated", actionable: false, fraud_type: "made_with_stolen_card", created: 1699116878)
    body = {
      id: processor_id,
      object: "radar.early_fraud_warning",
      actionable: actionable,
      charge: {
        id: charge_id,
        object: "charge",
        outcome: { risk_level: risk_level }
      },
      created: created,
      fraud_type: fraud_type,
      livemode: false
    }
    stub_request(:get, %r{https?://[^/]+/v1/radar/early_fraud_warnings/#{processor_id}.*})
      .to_return(status: 200, body: body.to_json,
                 headers: { "Content-Type" => "application/json", "Request-Id" => "req_x" })
  end

  def base_efw_params(extra = {})
    {
      "id" => "evt_radar_efw_test",
      "object" => "event",
      "api_version" => "2020-08-27",
      "created" => 1699116878,
      "data" => {
        "object" => {
          "id" => "issfr_test_efw_1",
          "object" => "radar.early_fraud_warning",
          "actionable" => false,
          "charge" => "ch_test_radar_processor",
          "created" => 1699116878,
          "fraud_type" => "made_with_stolen_card",
          "livemode" => false,
          "payment_intent" => "pi_test_radar_processor"
        }.merge(extra)
      },
      "livemode" => false,
      "pending_webhooks" => 8,
      "request" => {
        "id" => "req_test",
        "idempotency_key" => "test-idempotency"
      },
      "type" => "radar.early_fraud_warning.created"
    }
  end

  def purchase_fixture
    purchases(:auto_invoice_enabled_purchase)
  end

  test "raises error for unsupported event type" do
    err = assert_raises(RuntimeError) do
      StripeChargeRadarProcessor.handle_event(base_efw_params.merge("type" => "charge.succeeded"))
    end
    assert_match(/Unsupported event type/, err.message)
  end

  test "without Stripe Connect, when purchase doesn't exist (test env) does nothing" do
    initial = EarlyFraudWarning.count
    StripeChargeRadarProcessor.handle_event(base_efw_params)
    assert_equal initial, EarlyFraudWarning.count
  end

  test "without Stripe Connect, when purchase doesn't exist (prod env) raises RecordNotFound" do
    original = Rails.env
    Rails.singleton_class.send(:define_method, :env) { ActiveSupport::StringInquirer.new("production") }
    begin
      assert_raises(ActiveRecord::RecordNotFound) do
        StripeChargeRadarProcessor.handle_event(base_efw_params)
      end
    ensure
      Rails.singleton_class.send(:define_method, :env) { original }
    end
  end

  test "with Stripe Connect, no purchase exists, never raises (test env)" do
    params = base_efw_params.merge("account" => "acct_connect_test")
    initial = EarlyFraudWarning.count
    StripeChargeRadarProcessor.handle_event(params)
    assert_equal initial, EarlyFraudWarning.count
  end

  test "with Stripe Connect, no purchase exists, never raises (prod env)" do
    params = base_efw_params.merge("account" => "acct_connect_test")
    original = Rails.env
    Rails.singleton_class.send(:define_method, :env) { ActiveSupport::StringInquirer.new("production") }
    begin
      initial = EarlyFraudWarning.count
      StripeChargeRadarProcessor.handle_event(params)
      assert_equal initial, EarlyFraudWarning.count
    ensure
      Rails.singleton_class.send(:define_method, :env) { original }
    end
  end

  test "created event for a Purchase creates a new EarlyFraudWarning and enqueues processing job" do
    purchase = purchase_fixture
    purchase.update_column(:stripe_transaction_id, "ch_efw_purchase_test")
    stub_efw_retrieve("issfr_efw_purchase_test", charge_id: "ch_efw_purchase_test")
    params = base_efw_params
    params["data"]["object"]["charge"] = "ch_efw_purchase_test"
    params["data"]["object"]["id"] = "issfr_efw_purchase_test"

    Sidekiq::Testing.fake! do
      ProcessEarlyFraudWarningJob.jobs.clear
      assert_difference -> { EarlyFraudWarning.count }, 1 do
        StripeChargeRadarProcessor.handle_event(params)
      end
      efw = EarlyFraudWarning.last
      assert_equal "issfr_efw_purchase_test", efw.processor_id
      assert_equal purchase, efw.purchase
      assert_nil efw.charge
      assert_equal 1, ProcessEarlyFraudWarningJob.jobs.size
      assert_equal [efw.id], ProcessEarlyFraudWarningJob.jobs.last["args"]
    end
  end

  test "updated event reuses the existing EarlyFraudWarning record" do
    purchase = purchase_fixture
    purchase.update_column(:stripe_transaction_id, "ch_efw_updated_test")
    efw = EarlyFraudWarning.new(
      purchase: purchase,
      processor_id: "issfr_efw_updated_test",
      actionable: true,
      fraud_type: "made_with_stolen_card",
      charge_risk_level: "elevated",
      processor_created_at: Time.current
    )
    efw.save!

    stub_efw_retrieve("issfr_efw_updated_test", charge_id: "ch_efw_updated_test", actionable: false)
    params = base_efw_params.merge("type" => "radar.early_fraud_warning.updated")
    params["data"]["object"]["charge"] = "ch_efw_updated_test"
    params["data"]["object"]["id"] = "issfr_efw_updated_test"
    params["data"]["object"]["actionable"] = false
    params["data"]["previous_attributes"] = { "actionable" => true }

    Sidekiq::Testing.fake! do
      ProcessEarlyFraudWarningJob.jobs.clear
      assert_no_difference -> { EarlyFraudWarning.count } do
        StripeChargeRadarProcessor.handle_event(params)
      end
      assert_equal false, efw.reload.actionable
      assert_equal 1, ProcessEarlyFraudWarningJob.jobs.size
    end
  end
end
