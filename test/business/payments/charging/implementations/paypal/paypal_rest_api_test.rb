# frozen_string_literal: true

require "test_helper"

class PaypalRestApiTest < ActiveSupport::TestCase
  setup do
    @api = PaypalRestApi.new
    # Stub the PayPal partner credentials so we never hit the live oauth2/token endpoint.
    PaypalPartnerRestCredentials.class_eval do
      alias_method :__orig_auth_token, :auth_token
      define_method(:auth_token) { "Bearer test-paypal-token" }
    end

    # The PayPal SDK's HTTP client mutates request headers in-place and clashes with
    # the frozen string literals in our `rest_api_headers`. Replace the live client
    # with a fake that exposes the @request and returns a stubbed response shaped
    # like PayPal SDK responses.
    @captured_requests = []
    captured_requests = @captured_requests
    fake_client = Object.new
    fake_client.define_singleton_method(:execute) do |req|
      captured_requests << req
      # Run an actual HTTP call via Net::HTTP so WebMock stubs can match.
      uri = URI.parse("https://api.sandbox.paypal.com#{req.path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      klass = case req.verb.to_s.upcase
              when "GET" then Net::HTTP::Get
              when "POST" then Net::HTTP::Post
              when "PATCH" then Net::HTTP::Patch
              when "DELETE" then Net::HTTP::Delete
              when "PUT" then Net::HTTP::Put
              end
      http_req = klass.new(uri.request_uri)
      http_req.body = req.body.to_json unless req.body.is_a?(Hash) && req.body.empty?
      response = http.request(http_req)
      result_obj = begin
        JSON.parse(response.body, object_class: OpenStruct)
      rescue StandardError
        OpenStruct.new
      end
      OpenStruct.new(status_code: response.code.to_i, result: result_obj, headers: response.to_hash)
    end
    @api.instance_variable_set(:@paypal_client, fake_client)
  end

  teardown do
    PaypalPartnerRestCredentials.class_eval do
      remove_method :auth_token
      alias_method :auth_token, :__orig_auth_token
      remove_method :__orig_auth_token
    end
  end

  test "#new_request shapes the OpenStruct with path, verb, headers, and body" do
    req = @api.new_request(path: "/v2/checkout/orders", verb: "POST")
    assert_equal "/v2/checkout/orders", req.path
    assert_equal "POST", req.verb
    assert_kind_of Hash, req.headers
    assert_equal({}, req.body)
    assert_includes req.headers, "Authorization"
    assert_equal "Bearer test-paypal-token", req.headers["Authorization"]
    assert_equal "application/json", req.headers["Content-Type"]
  end

  test "#successful_response? returns true for 200-299" do
    assert @api.successful_response?(OpenStruct.new(status_code: 200))
    assert @api.successful_response?(OpenStruct.new(status_code: 201))
    assert @api.successful_response?(OpenStruct.new(status_code: 299))
    refute @api.successful_response?(OpenStruct.new(status_code: 300))
    refute @api.successful_response?(OpenStruct.new(status_code: 199))
    refute @api.successful_response?(OpenStruct.new(status_code: 404))
    refute @api.successful_response?(OpenStruct.new(status_code: 500))
  end

  test "#generate_billing_agreement_token issues POST to /v1/billing-agreements/agreement-tokens with PAYPAL plan" do
    captured = nil
    PayPal::PayPalHttpClient.any_instance.define_singleton_method(:execute) { |req| captured = req; OpenStruct.new(status_code: 201, result: OpenStruct.new(token_id: "EC-test")) } if false
    # Use the real client but intercept via webmock at the http boundary
    stub_request(:post, "https://api.sandbox.paypal.com/v1/billing-agreements/agreement-tokens")
      .to_return(status: 201, body: { token_id: "EC-test" }.to_json,
                 headers: { "Content-Type" => "application/json", "Paypal-Debug-Id" => "x" })

    response = @api.generate_billing_agreement_token
    assert_equal 201, response.status_code
  end

  test "#create_billing_agreement POSTs to /v1/billing-agreements/agreements with token id in body" do
    received_body = nil
    stub_request(:post, "https://api.sandbox.paypal.com/v1/billing-agreements/agreements")
      .with { |req| received_body = req.body; true }
      .to_return(status: 201, body: { id: "BA-test" }.to_json,
                 headers: { "Content-Type" => "application/json", "Paypal-Debug-Id" => "x" })

    response = @api.create_billing_agreement(billing_agreement_token_id: "EC-token-xyz")
    assert_equal 201, response.status_code
    assert_match(/EC-token-xyz/, received_body.to_s)
  end

  test "#create_order POSTs to /v2/checkout/orders and returns the order" do
    stub_request(:post, "https://api.sandbox.paypal.com/v2/checkout/orders")
      .to_return(status: 201, body: { id: "ORD-test", status: "CREATED" }.to_json,
                 headers: { "Content-Type" => "application/json", "Paypal-Debug-Id" => "x" })

    info = {
      currency: "USD", total: "15.00", shipping: "1.50", tax: "0.00", price: "13.50",
      merchant_id: "MERCHANT123", item_name: "test product", descriptor: "Gumroad",
      unit_price: "4.50", quantity: 3, product_permalink: "aa", fee: "1.50", invoice_id: nil
    }
    response = @api.create_order(purchase_unit_info: info)
    assert_equal 201, response.status_code
  end

  test "#fetch_order GETs /v2/checkout/orders/:id" do
    stub_request(:get, "https://api.sandbox.paypal.com/v2/checkout/orders/ORD-fetch-test")
      .to_return(status: 200, body: { id: "ORD-fetch-test", status: "CREATED" }.to_json,
                 headers: { "Content-Type" => "application/json", "Paypal-Debug-Id" => "x" })

    response = @api.fetch_order(order_id: "ORD-fetch-test")
    assert_equal 200, response.status_code
  end

  test "#update_invoice_id PATCHes invoice id onto an order" do
    stub_request(:patch, "https://api.sandbox.paypal.com/v2/checkout/orders/ORD-upd")
      .to_return(status: 204, body: "", headers: { "Paypal-Debug-Id" => "x" })

    response = @api.update_invoice_id(order_id: "ORD-upd", invoice_id: "inv-789")
    assert_equal 204, response.status_code
  end

  test "#capture POSTs to /v2/checkout/orders/:id/capture" do
    stub_request(:post, "https://api.sandbox.paypal.com/v2/checkout/orders/ORD-cap/capture")
      .to_return(status: 201, body: { id: "ORD-cap", status: "COMPLETED" }.to_json,
                 headers: { "Content-Type" => "application/json", "Paypal-Debug-Id" => "x" })

    response = @api.capture(order_id: "ORD-cap", billing_agreement_id: nil)
    assert_equal 201, response.status_code
  end

  test "#capture includes payment_source.token when billing_agreement_id is provided" do
    body_seen = nil
    stub_request(:post, "https://api.sandbox.paypal.com/v2/checkout/orders/ORD-cap/capture")
      .with { |req| body_seen = req.body; true }
      .to_return(status: 201, body: { id: "ORD-cap", status: "COMPLETED" }.to_json,
                 headers: { "Content-Type" => "application/json", "Paypal-Debug-Id" => "x" })

    @api.capture(order_id: "ORD-cap", billing_agreement_id: "BA-1234")
    assert_match(/BA-1234/, body_seen.to_s)
    assert_match(/BILLING_AGREEMENT/, body_seen.to_s)
  end
end
