# frozen_string_literal: true

require "test_helper"

class BraintreeChargeProcessorTest < ActiveSupport::TestCase
  fixtures :merchant_accounts

  setup do
    @processor = BraintreeChargeProcessor.new

    # Short-circuit BraintreeCharge's PayPal SDK callout for any path that
    # constructs a BraintreeCharge with load_extra_details: true.
    BraintreeCharge.define_method(:load_details_from_paypal) { |_| nil }
  end

  teardown do
    if BraintreeCharge.private_instance_methods(false).include?(:load_details_from_paypal) ||
       BraintreeCharge.instance_methods(false).include?(:load_details_from_paypal)
      BraintreeCharge.remove_method(:load_details_from_paypal)
    end
  end

  # ---- helpers to build realistic-shaped Braintree::Transaction stubs ----

  def build_credit_card_details(token: "ccTokABC", email: "jane.doe@example.com")
    Struct.new(:token, :last_4, :card_type, :expiration_month, :expiration_year, :country_of_issuance, keyword_init: true).new(
      token: token, last_4: nil, card_type: nil,
      expiration_month: nil, expiration_year: nil, country_of_issuance: nil
    )
  end

  def build_transaction(status: Braintree::Transaction::Status::Settled, id: "txn_abc123", amount: 225.0,
                       customer_id: "cust_paypal_1", refunded_transaction_id: nil,
                       gateway_rejection_reason: nil, processor_response_code: nil, processor_response_text: nil,
                       processor_settlement_response_code: nil, processor_settlement_response_text: nil)
    cc = build_credit_card_details
    Struct.new(
      :id, :status, :amount, :credit_card_details, :paypal_details, :customer_details,
      :refunded?, :refunded_transaction_id, :gateway_rejection_reason,
      :processor_response_code, :processor_response_text,
      :processor_settlement_response_code, :processor_settlement_response_text,
      keyword_init: true
    ).new(
      id: id, status: status, amount: amount,
      credit_card_details: cc,
      paypal_details: Struct.new(:capture_id, keyword_init: true).new(capture_id: "paypal_capture_id"),
      customer_details: Struct.new(:id, keyword_init: true).new(id: customer_id),
      refunded?: false, refunded_transaction_id: refunded_transaction_id,
      gateway_rejection_reason: gateway_rejection_reason,
      processor_response_code: processor_response_code,
      processor_response_text: processor_response_text,
      processor_settlement_response_code: processor_settlement_response_code,
      processor_settlement_response_text: processor_settlement_response_text
    )
  end

  def build_success_sale_result(transaction)
    Struct.new(:transaction, :errors, keyword_init: true).new(
      transaction: transaction,
      errors: Struct.new(:any?).new(false)
    )
  end

  def build_failure_sale_result(transaction:, error: nil)
    errors_obj = if error
      Struct.new(:any?, :first).new(true, error)
    else
      Struct.new(:any?).new(false)
    end
    Struct.new(:transaction, :errors, keyword_init: true).new(transaction: transaction, errors: errors_obj)
  end

  # ---- .charge_processor_id ----

  test ".charge_processor_id returns 'braintree'" do
    assert_equal "braintree", BraintreeChargeProcessor.charge_processor_id
  end

  # ---- #get_chargeable_for_params ----

  test "#get_chargeable_for_params returns nil with empty params" do
    assert_nil @processor.get_chargeable_for_params({}, nil)
  end

  test "#get_chargeable_for_params with only nonce returns a BraintreeChargeableNonce" do
    result = @processor.get_chargeable_for_params({ braintree_nonce: "fake-paypal-nonce" }, nil)
    assert_instance_of BraintreeChargeableNonce, result
  end

  test "#get_chargeable_for_params with transient customer store key returns a BraintreeChargeableTransientCustomer" do
    key = "btc_test_key_#{SecureRandom.hex(4)}"
    store = Redis::Namespace.new(:transient_braintree_customer_store, redis: $redis)
    store.set(key, ObfuscateIds.encrypt(123_456))
    begin
      result = @processor.get_chargeable_for_params({ braintree_transient_customer_store_key: key }, nil)
      assert_instance_of BraintreeChargeableTransientCustomer, result
    ensure
      store.del(key)
    end
  end

  test "#get_chargeable_for_params propagates braintree_device_data onto the chargeable (nonce path)" do
    device_data = { dummy_session_id: "dummy" }.to_json
    result = @processor.get_chargeable_for_params(
      { braintree_nonce: "fake-paypal-nonce", braintree_device_data: device_data }, nil
    )
    assert_instance_of BraintreeChargeableNonce, result
    assert_equal device_data, result.braintree_device_data
  end

  test "#get_chargeable_for_params propagates braintree_device_data onto the chargeable (transient customer path)" do
    device_data = { dummy_session_id: "dummy" }.to_json
    key = "btc_test_key_#{SecureRandom.hex(4)}"
    store = Redis::Namespace.new(:transient_braintree_customer_store, redis: $redis)
    store.set(key, ObfuscateIds.encrypt(123_456))
    begin
      result = @processor.get_chargeable_for_params(
        { braintree_transient_customer_store_key: key, braintree_device_data: device_data }, nil
      )
      assert_instance_of BraintreeChargeableTransientCustomer, result
      assert_equal device_data, result.braintree_device_data
    ensure
      store.del(key)
    end
  end

  # ---- #get_chargeable_for_data ----

  test "#get_chargeable_for_data with customer id returns a BraintreeChargeableCreditCard" do
    result = @processor.get_chargeable_for_data(
      "cust_token_xyz", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
    )
    assert_instance_of BraintreeChargeableCreditCard, result
    assert_equal "cust_token_xyz", result.braintree_customer_id
  end

  # ---- #get_charge ----

  test "#get_charge raises ChargeProcessorInvalidRequestError on invalid id (NotFoundError)" do
    Braintree::Transaction.stub(:find, ->(*) { raise Braintree::NotFoundError }) do
      assert_raises(ChargeProcessorInvalidRequestError) { @processor.get_charge("invalid") }
    end
  end

  test "#get_charge with a valid id returns a BraintreeCharge" do
    txn = build_transaction(id: "txn_valid")

    paypal_payment_method = Braintree::PayPalAccount._new(
      Braintree::Configuration.gateway,
      email: "jane.doe@example.com",
      token: "ccTokABC"
    )

    Braintree::Transaction.stub(:find, txn) do
      Braintree::PaymentMethod.stub(:find, paypal_payment_method) do
        charge = @processor.get_charge("txn_valid")
        assert_instance_of BraintreeCharge, charge
        assert_equal "braintree", charge.charge_processor_id
        assert_nil charge.zip_check_result
        assert_equal "txn_valid", charge.id
        assert_nil charge.fee
        assert_equal "paypal_jane.doe@example.com", charge.card_fingerprint
      end
    end
  end

  test "#get_charge raises ChargeProcessorUnavailableError when processor is unavailable" do
    Braintree::Transaction.stub(:find, ->(*) { raise Braintree::ServiceUnavailableError }) do
      assert_raises(ChargeProcessorUnavailableError) { @processor.get_charge("a-charge-id") }
    end
  end

  # ---- #search_charge ----

  test "#search_charge returns the first transaction matched on the purchase's external_id" do
    txn = build_transaction(id: "f4ajns4e")
    purchase = Minitest::Mock.new
    purchase.expect(:external_id, "50WuYB5aQYhDx2gzaxhP-Q==")

    original = Braintree::Transaction.method(:search)
    Braintree::Transaction.define_singleton_method(:search) do |&block|
      search_obj = Object.new
      search_obj.define_singleton_method(:order_id) { o = Object.new; o.define_singleton_method(:is) { |_| nil }; o }
      block.call(search_obj) if block
      [txn]
    end
    begin
      result = @processor.search_charge(purchase: purchase)
      assert_same txn, result
      assert_equal "f4ajns4e", result.id
      assert_equal Braintree::Transaction::Status::Settled, result.status
    ensure
      Braintree::Transaction.define_singleton_method(:search, original)
    end
  end

  test "#search_charge returns nil when no transactions match" do
    purchase = Minitest::Mock.new
    purchase.expect(:external_id, "no-match-token")

    original = Braintree::Transaction.method(:search)
    Braintree::Transaction.define_singleton_method(:search) do |&block|
      search_obj = Object.new
      search_obj.define_singleton_method(:order_id) { o = Object.new; o.define_singleton_method(:is) { |_| nil }; o }
      block.call(search_obj) if block
      []
    end
    begin
      assert_nil @processor.search_charge(purchase: purchase)
    ensure
      Braintree::Transaction.define_singleton_method(:search, original)
    end
  end

  # ---- #create_payment_intent_or_charge! ----

  test "#create_payment_intent_or_charge! returns a BraintreeChargeIntent wrapping a BraintreeCharge on success" do
    merchant_account = merchant_accounts(:forfeit_gumroad_braintree_account)
    chargeable = BraintreeChargeableCreditCard.new("cust_paypal_1", nil, nil, nil, nil, nil, nil, nil, nil)
    txn = build_transaction(id: "txn_success", amount: 225.0, customer_id: "cust_paypal_1")
    sale_result = build_success_sale_result(txn)

    Braintree::Transaction.stub(:sale, sale_result) do
      intent = @processor.create_payment_intent_or_charge!(
        merchant_account, chargeable, 225_00, 0, "product-id", nil, statement_description: "dummy"
      )
      assert_instance_of BraintreeChargeIntent, intent
      charge = intent.charge
      assert_instance_of BraintreeCharge, charge
      assert_equal "braintree", charge.charge_processor_id
      assert_equal "txn_success", charge.id
    end
  end

  test "#create_payment_intent_or_charge! raises ChargeProcessorUnavailableError when service unavailable" do
    merchant_account = merchant_accounts(:forfeit_gumroad_braintree_account)
    chargeable = BraintreeChargeableCreditCard.new("cust_paypal_1", nil, nil, nil, nil, nil, nil, nil, nil)

    Braintree::Transaction.stub(:sale, ->(*) { raise Braintree::ServiceUnavailableError }) do
      assert_raises(ChargeProcessorUnavailableError) do
        @processor.create_payment_intent_or_charge!(
          merchant_account, chargeable, 225_00, 0, "product-id", nil, statement_description: "dummy"
        )
      end
    end
  end

  test "#create_payment_intent_or_charge! raises ChargeProcessorCardError with Declined details on validation failure" do
    merchant_account = merchant_accounts(:forfeit_gumroad_braintree_account)
    chargeable = BraintreeChargeableCreditCard.new("cust_paypal_1", nil, nil, nil, nil, nil, nil, nil, nil)

    txn = build_transaction(status: Braintree::Transaction::Status::ProcessorDeclined,
                            processor_response_code: "2046",
                            processor_response_text: "Declined")
    sale_result = build_failure_sale_result(transaction: txn,
                                            error: Struct.new(:code, :message).new("2046", "Declined"))

    Braintree::Transaction.stub(:sale, sale_result) do
      err = assert_raises(ChargeProcessorCardError) do
        @processor.create_payment_intent_or_charge!(
          merchant_account, chargeable, 204_600, 0, "product-id", nil, statement_description: "dummy"
        )
      end
      assert_equal "2046", err.error_code
      assert_equal "Declined", err.message
    end
  end

  test "#create_payment_intent_or_charge! raises ChargeProcessorUnsupportedPaymentAccountError on PayPal account unsupported (2071)" do
    merchant_account = merchant_accounts(:forfeit_gumroad_braintree_account)
    chargeable = BraintreeChargeableCreditCard.new("cust_paypal_1", nil, nil, nil, nil, nil, nil, nil, nil)

    txn = build_transaction(status: Braintree::Transaction::Status::ProcessorDeclined,
                            processor_response_code: "2071",
                            processor_response_text: "Unsupported PayPal account")
    sale_result = build_failure_sale_result(transaction: txn)

    Braintree::Transaction.stub(:sale, sale_result) do
      assert_raises(ChargeProcessorUnsupportedPaymentAccountError) do
        @processor.create_payment_intent_or_charge!(
          merchant_account, chargeable, 207_100, 0, "product-id", nil, statement_description: "dummy"
        )
      end
    end
  end

  test "#create_payment_intent_or_charge! raises ChargeProcessorUnsupportedPaymentTypeError on PayPal instrument unsupported (2074)" do
    merchant_account = merchant_accounts(:forfeit_gumroad_braintree_account)
    chargeable = BraintreeChargeableCreditCard.new("cust_paypal_1", nil, nil, nil, nil, nil, nil, nil, nil)

    txn = build_transaction(status: Braintree::Transaction::Status::ProcessorDeclined,
                            processor_response_code: "2074",
                            processor_response_text: "Unsupported PayPal instrument")
    sale_result = build_failure_sale_result(transaction: txn)

    Braintree::Transaction.stub(:sale, sale_result) do
      assert_raises(ChargeProcessorUnsupportedPaymentTypeError) do
        @processor.create_payment_intent_or_charge!(
          merchant_account, chargeable, 207_400, 0, "product-id", nil, statement_description: "dummy"
        )
      end
    end
  end

  test "#create_payment_intent_or_charge! raises ChargeProcessorCardError with settlement declined details (4001)" do
    merchant_account = merchant_accounts(:forfeit_gumroad_braintree_account)
    chargeable = BraintreeChargeableCreditCard.new("cust_paypal_1", nil, nil, nil, nil, nil, nil, nil, nil)

    txn = build_transaction(status: Braintree::Transaction::Status::SettlementDeclined,
                            processor_settlement_response_code: "4001",
                            processor_settlement_response_text: "Settlement Declined")
    sale_result = build_failure_sale_result(transaction: txn)

    Braintree::Transaction.stub(:sale, sale_result) do
      err = assert_raises(ChargeProcessorCardError) do
        @processor.create_payment_intent_or_charge!(
          merchant_account, chargeable, 400_100, 0, "product-id", nil, statement_description: "dummy"
        )
      end
      assert_equal "4001", err.error_code
      assert_equal "Settlement Declined", err.message
    end
  end

  # ---- #refund! ----

  test "#refund! raises ChargeProcessorUnavailableError when processor is unavailable" do
    Braintree::Transaction.stub(:refund!, ->(*) { raise Braintree::ServiceUnavailableError }) do
      assert_raises(ChargeProcessorUnavailableError) { @processor.refund!("dummy") }
    end
  end

  test "#refund! raises ChargeProcessorInvalidRequestError on a non-existant transaction" do
    validation_result = Struct.new(:errors).new([])
    Braintree::Transaction.stub(:refund!, ->(*) { raise Braintree::ValidationsFailed.new(validation_result) }) do
      assert_raises(ChargeProcessorInvalidRequestError) { @processor.refund!("invalid-charge-id") }
    end
  end

  test "#refund! returns a BraintreeChargeRefund on success" do
    refund_txn = build_transaction(id: "refund_abc", amount: 225.0, refunded_transaction_id: "txn_original")
    Braintree::Transaction.stub(:refund!, refund_txn) do
      refund = @processor.refund!("txn_original")
      assert_instance_of BraintreeChargeRefund, refund
      assert_equal "refund_abc", refund.id
      assert_equal "txn_original", refund.charge_id
    end
  end

  test "#refund! with amount_cents passes the dollar amount through to Braintree::Transaction.refund!" do
    refund_txn = build_transaction(id: "refund_partial", amount: 125.0, refunded_transaction_id: "txn_original")
    seen_args = []
    fake_refund = ->(*args) { seen_args = args; refund_txn }
    Braintree::Transaction.stub(:refund!, fake_refund) do
      refund = @processor.refund!("txn_original", amount_cents: 125_00)
      assert_instance_of BraintreeChargeRefund, refund
      assert_equal "refund_partial", refund.id
      assert_equal ["txn_original", 125.0], seen_args
    end
  end

  test "#refund! raises ChargeProcessorAlreadyRefundedError when braintree returns the already-refunded error code" do
    refunded_err = Struct.new(:code, :message).new(
      Braintree::ErrorCodes::Transaction::HasAlreadyBeenRefunded,
      "Transaction has already been fully refunded."
    )
    validation_result = Struct.new(:errors).new([refunded_err])
    Braintree::Transaction.stub(:refund!, ->(*) { raise Braintree::ValidationsFailed.new(validation_result) }) do
      assert_raises(ChargeProcessorAlreadyRefundedError) { @processor.refund!("txn_original") }
    end
  end

  test "#refund! raises ChargeProcessorInvalidRequestError when braintree returns a ValidationsFailed with no errors" do
    validation_result = Struct.new(:errors).new([])
    Braintree::Transaction.stub(:refund!, ->(*) { raise Braintree::ValidationsFailed.new(validation_result) }) do
      assert_raises(ChargeProcessorInvalidRequestError) { @processor.refund!("txn_original") }
    end
  end

  # ---- #holder_of_funds ----

  test "#holder_of_funds returns Gumroad for the gumroad braintree merchant account" do
    merchant_account = merchant_accounts(:forfeit_gumroad_braintree_account)
    assert_equal HolderOfFunds::GUMROAD, @processor.holder_of_funds(merchant_account)
  end

  # ---- #transaction_url ----

  test "#transaction_url builds the sandbox URL outside production" do
    url = @processor.transaction_url("txn_abc")
    assert_includes url, "sandbox.braintreegateway.com"
    assert_includes url, "/transactions/txn_abc"
  end
end
