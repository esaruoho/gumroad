# frozen_string_literal: true

require "test_helper"

class BraintreeChargeableTransientCustomerTest < ActiveSupport::TestCase
  setup do
    @transient_customer_store_key = "transient-customer-token-key"
    @transient_store = Redis::Namespace.new(:transient_braintree_customer_store, redis: $redis)
    @transient_store.del(@transient_customer_store_key)
    @transient_store.del("braintree_transient_customer_store_key")
  end

  teardown do
    @transient_store.del(@transient_customer_store_key)
    @transient_store.del("braintree_transient_customer_store_key")
  end

  def build_paypal_customer(id: "123456", email: "jane.doe@example.com")
    paypal_account = Braintree::PayPalAccount._new(
      Braintree::Configuration.gateway,
      email: email,
      token: "pp_#{id}"
    )
    customer = Braintree::Customer._new(
      Braintree::Configuration.gateway,
      id: id,
      paypal_accounts: [],
      credit_cards: []
    )
    customer.instance_variable_set(:@paypal_accounts, [paypal_account])
    customer.instance_variable_set(:@credit_cards, [])
    customer
  end

  # ---- tokenize_nonce_to_transient_customer ----

  test "tokenize_nonce_to_transient_customer stores the customer id with an expiry in redis" do
    Braintree::Customer.stub(:create!, build_paypal_customer) do
      result = BraintreeChargeableTransientCustomer.tokenize_nonce_to_transient_customer(
        "fake-paypal-nonce", @transient_customer_store_key
      )

      assert_instance_of BraintreeChargeableTransientCustomer, result
      token = @transient_store.get(@transient_customer_store_key)
      refute_nil token
      assert_equal "123456", ObfuscateIds.decrypt(token).to_s

      ttl = $redis.ttl("transient_braintree_customer_store:#{@transient_customer_store_key}")
      assert_operator ttl, :>, 0
      assert_operator ttl, :<=, 5 * 60
    end
  end

  test "tokenize_nonce_to_transient_customer raises ChargeProcessorInvalidRequestError on validation failure" do
    validation_result = Struct.new(:errors).new([])
    Braintree::Customer.stub(:create!, ->(*) { raise Braintree::ValidationsFailed.new(validation_result) }) do
      assert_raises(ChargeProcessorInvalidRequestError) do
        BraintreeChargeableTransientCustomer.tokenize_nonce_to_transient_customer(
          "invalid", @transient_customer_store_key
        )
      end
    end
  end

  test "tokenize_nonce_to_transient_customer raises ChargeProcessorUnavailableError when service down" do
    Braintree::Customer.stub(:create!, ->(*) { raise Braintree::ServiceUnavailableError }) do
      assert_raises(ChargeProcessorUnavailableError) do
        BraintreeChargeableTransientCustomer.tokenize_nonce_to_transient_customer(
          "fake-nonce", @transient_customer_store_key
        )
      end
    end
  end

  test "tokenize_nonce_to_transient_customer returns nil for blank nonce" do
    assert_nil BraintreeChargeableTransientCustomer.tokenize_nonce_to_transient_customer(nil, @transient_customer_store_key)
    assert_nil BraintreeChargeableTransientCustomer.tokenize_nonce_to_transient_customer("", @transient_customer_store_key)
  end

  # ---- from_transient_customer_store_key ----

  test "from_transient_customer_store_key raises when storage has no contents" do
    assert_raises(ChargeProcessorInvalidRequestError) do
      BraintreeChargeableTransientCustomer.from_transient_customer_store_key("this-key-doesnt-exist")
    end
  end

  test "from_transient_customer_store_key returns a constructed object when storage has contents" do
    Braintree::Customer.stub(:create!, build_paypal_customer) do
      BraintreeChargeableTransientCustomer.tokenize_nonce_to_transient_customer(
        "fake-paypal-nonce", @transient_customer_store_key
      )
    end

    rebuilt = BraintreeChargeableTransientCustomer.from_transient_customer_store_key(@transient_customer_store_key)
    assert_instance_of BraintreeChargeableTransientCustomer, rebuilt
    assert_equal "123456", rebuilt.customer_id.to_s
  end

  # ---- prepare! ----

  test "prepare! raises on invalid customer ID (NotFoundError)" do
    Braintree::Customer.stub(:find, ->(*) { raise Braintree::NotFoundError }) do
      chargeable = BraintreeChargeableTransientCustomer.new("invalid", nil)
      assert_raises(ChargeProcessorInvalidRequestError) { chargeable.prepare! }
    end
  end

  test "prepare! succeeds when customer is found and exposes paypal fingerprint" do
    Braintree::Customer.stub(:find, build_paypal_customer) do
      chargeable = BraintreeChargeableTransientCustomer.new("123456", nil)
      assert chargeable.prepare!
      assert_equal "paypal_jane.doe@example.com", chargeable.fingerprint
    end
  end

  test "#charge_processor_id returns 'braintree'" do
    chargeable = BraintreeChargeableTransientCustomer.new(nil, nil)
    assert_equal "braintree", chargeable.charge_processor_id
  end
end
