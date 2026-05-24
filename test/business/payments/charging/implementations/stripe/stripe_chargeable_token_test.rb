# frozen_string_literal: true

require "test_helper"

class StripeChargeableTokenTest < ActiveSupport::TestCase
  setup do
    @orig_api_base = Stripe.api_base
    @orig_api_key = Stripe.api_key
    Stripe.api_base = "http://127.0.0.1:12111"
    Stripe.api_key = "sk_test_xxx"
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  teardown do
    Stripe.api_base = @orig_api_base
    Stripe.api_key = @orig_api_key
  end

  def make_token
    Stripe::Token.create(
      card: { number: "4242424242424242", exp_month: 12, exp_year: 2050, cvc: "123", address_zip: "12345" }
    )
  end

  def make_chargeable
    token = make_token
    StripeChargeableToken.new(token.id, "12345", product_permalink: "xx")
  end

  test "#charge_processor_id returns stripe" do
    assert_equal "stripe", make_chargeable.charge_processor_id
  end

  test "#prepare! retrieves the token from Stripe" do
    c = make_chargeable
    assert_equal true, c.prepare!
    assert_equal "4242", c.last4
  end

  test "#fingerprint, #last4, #expiry_*, #number_length, #visual, #card_type, #country populated after prepare!" do
    c = make_chargeable
    c.prepare!
    assert_not_nil c.fingerprint
    assert_equal "4242", c.last4
    assert_equal 16, c.number_length
    assert_equal "**** **** **** 4242", c.visual
    assert_kind_of Integer, c.expiry_month
    assert_kind_of Integer, c.expiry_year
    assert_not_nil c.card_type
    assert_not_nil c.country
  end

  test "#zip_code falls through to initializer arg before prepare!" do
    c = StripeChargeableToken.new("tok_unfetched", "99999", product_permalink: "xx")
    assert_equal "99999", c.zip_code
  end

  test "#reusable_token! creates a customer on Stripe and returns its id" do
    stub_request(:post, "http://127.0.0.1:12111/v1/customers")
      .to_return(status: 200, body: { id: "cus_token_test", sources: { data: [] } }.to_json,
                 headers: { "Content-Type" => "application/json", "Request-Id" => "req_x" })

    c = make_chargeable
    user = users(:basic_user)
    token = c.reusable_token!(user)
    assert_equal "cus_token_test", token
    # Cached: subsequent calls reuse, don't hit Stripe again
    assert_equal "cus_token_test", c.reusable_token!(user)
  end

  test "#stripe_charge_params returns customer + nil payment_method after reusable_token!" do
    stub_request(:post, "http://127.0.0.1:12111/v1/customers")
      .to_return(status: 200, body: { id: "cus_token_cp", sources: { data: [] } }.to_json,
                 headers: { "Content-Type" => "application/json", "Request-Id" => "req_x" })

    c = make_chargeable
    params = c.stripe_charge_params
    assert_equal "cus_token_cp", params[:customer]
    assert_nil params[:payment_method]
  end

  test "#requires_mandate? mirrors card country" do
    c = make_chargeable
    c.prepare!
    assert_equal (c.country == "IN"), c.requires_mandate?
  end
end
