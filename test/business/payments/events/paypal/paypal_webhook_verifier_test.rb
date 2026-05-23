# frozen_string_literal: true

require "test_helper"

class PaypalWebhookVerifierTest < ActiveSupport::TestCase
  def headers
    @headers ||= {
      "HTTP_PAYPAL_TRANSMISSION_ID" => "abc",
      "HTTP_PAYPAL_TRANSMISSION_SIG" => "sig",
      "HTTP_PAYPAL_CERT_URL" => "https://api.paypal.com/certs/123",
      "HTTP_PAYPAL_AUTH_ALGO" => "SHA256",
      "HTTP_PAYPAL_TRANSMISSION_TIME" => Time.current.httpdate
    }
  end

  def raw_body
    @raw_body ||= { event_type: PaypalEventType::PAYMENT_CAPTURE_REFUNDED }.to_json
  end

  def verifier
    PaypalWebhookVerifier.new(headers: headers, raw_body: raw_body, fallback_payload: JSON.parse(raw_body))
  end

  def stub_auth_token!
    PaypalPartnerRestCredentials.class_eval do
      alias_method :__orig_auth_token, :auth_token
      define_method(:auth_token) { "Bearer test" }
    end
  end

  def restore_auth_token!
    PaypalPartnerRestCredentials.class_eval do
      remove_method :auth_token
      alias_method :auth_token, :__orig_auth_token
      remove_method :__orig_auth_token
    end
  end

  def stub_post(response)
    captured = { calls: [] }
    PaypalWebhookVerifier.singleton_class.send(:alias_method, :__orig_post, :post)
    PaypalWebhookVerifier.define_singleton_method(:post) do |*args, **kwargs|
      captured[:calls] << [args, kwargs]
      raise response if response.is_a?(Class) && response < Exception
      response
    end
    captured
  ensure
    # restore happens via ensure_post_restored below
  end

  def restore_post
    PaypalWebhookVerifier.singleton_class.send(:remove_method, :post)
    PaypalWebhookVerifier.singleton_class.send(:alias_method, :post, :__orig_post)
    PaypalWebhookVerifier.singleton_class.send(:remove_method, :__orig_post)
  end

  def with_post_stub(response)
    captured = stub_post(response)
    stub_auth_token!
    yield captured
  ensure
    restore_post
    restore_auth_token!
  end

  def ok_response
    Struct.new(:code, :parsed_response).new(200, { "verification_status" => "SUCCESS" })
  end

  test "returns true when PayPal verifies the event" do
    with_const(:PAYPAL_WEBHOOK_ID, "TEST_WEBHOOK_ID") do
      with_post_stub(ok_response) do
        assert_equal true, verifier.valid?
      end
    end
  end

  test "returns false when PAYPAL_WEBHOOK_ID is blank" do
    with_const(:PAYPAL_WEBHOOK_ID, nil) do
      assert_equal false, verifier.valid?
    end
  end

  test "returns false when required headers are missing" do
    with_const(:PAYPAL_WEBHOOK_ID, "TEST_WEBHOOK_ID") do
      invalid = PaypalWebhookVerifier.new(
        headers: headers.except("HTTP_PAYPAL_TRANSMISSION_ID"),
        raw_body: raw_body,
        fallback_payload: {}
      )
      assert_equal false, invalid.valid?
    end
  end

  test "returns false when PayPal rejects the signature" do
    response = Struct.new(:code, :parsed_response).new(200, { "verification_status" => "FAILURE" })
    with_const(:PAYPAL_WEBHOOK_ID, "TEST_WEBHOOK_ID") do
      with_post_stub(response) do
        assert_equal false, verifier.valid?
      end
    end
  end

  test "returns false when PayPal returns an error response" do
    response = Struct.new(:code, :parsed_response).new(400, { "error" => "invalid_request" })
    with_const(:PAYPAL_WEBHOOK_ID, "TEST_WEBHOOK_ID") do
      with_post_stub(response) do
        assert_equal false, verifier.valid?
      end
    end
  end

  test "returns false and logs warning when network error occurs" do
    with_const(:PAYPAL_WEBHOOK_ID, "TEST_WEBHOOK_ID") do
      with_post_stub(Net::ReadTimeout) do
        warned = false
        Rails.logger.stub(:warn, ->(msg) { warned = true if msg =~ /PayPal webhook verification error/ }) do
          assert_equal false, verifier.valid?
        end
        assert warned, "expected a warning log about PayPal webhook verification error"
      end
    end
  end

  test "returns true when JSON parsing fails but PayPal verifies the event" do
    with_const(:PAYPAL_WEBHOOK_ID, "TEST_WEBHOOK_ID") do
      with_post_stub(ok_response) do
        invalid = PaypalWebhookVerifier.new(headers: headers, raw_body: "invalid json{", fallback_payload: {})
        assert_equal true, invalid.valid?
      end
    end
  end

  test "sends correct verification body to PayPal" do
    with_const(:PAYPAL_WEBHOOK_ID, "TEST_WEBHOOK_ID") do
      with_post_stub(ok_response) do |captured|
        verifier.valid?
        args, kwargs = captured[:calls].first
        assert_equal "/v1/notifications/verify-webhook-signature", args.first
        assert_equal({ "Content-Type" => "application/json", "Authorization" => "Bearer test" }, kwargs[:headers])
        assert_equal 30, kwargs[:timeout]
        body = JSON.parse(kwargs[:body])
        assert_equal "SHA256", body["auth_algo"]
        assert_equal "https://api.paypal.com/certs/123", body["cert_url"]
        assert_equal "abc", body["transmission_id"]
        assert_equal "sig", body["transmission_sig"]
        assert_equal headers["HTTP_PAYPAL_TRANSMISSION_TIME"], body["transmission_time"]
        assert_equal "TEST_WEBHOOK_ID", body["webhook_id"]
        assert_equal JSON.parse(raw_body), body["webhook_event"]
      end
    end
  end

  test "uses fallback_payload when raw_body is empty" do
    fallback = { "event_type" => "PAYMENT.CAPTURE.COMPLETED" }
    with_const(:PAYPAL_WEBHOOK_ID, "TEST_WEBHOOK_ID") do
      with_post_stub(ok_response) do |captured|
        empty = PaypalWebhookVerifier.new(headers: headers, raw_body: "", fallback_payload: fallback)
        empty.valid?
        _args, kwargs = captured[:calls].first
        body = JSON.parse(kwargs[:body])
        assert_equal fallback, body["webhook_event"]
      end
    end
  end
end
