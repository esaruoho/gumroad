# frozen_string_literal: true

require "test_helper"

class Admin::PaymentPresenterTest < ActiveSupport::TestCase
  setup do
    @payment = payments(:paypal_payment_recent)
  end

  def props_for(payment)
    Admin::PaymentPresenter.new(payment: payment).props
  end

  test "#props returns a hash with all expected keys" do
    props = props_for(@payment)
    expected_keys = %i[
      external_id displayed_amount payout_period_end_date created_at user state
      humanized_failure_reason failed cancelled returned processing unclaimed
      non_terminal_state processor is_stripe_processor is_paypal_processor
      processor_fee_cents stripe_transfer_id stripe_transfer_url
      stripe_connected_account_url stripe_connect_account_id bank_account txn_id
      payment_address correlation_id was_created_in_split_mode split_payments_info
    ]
    expected_keys.each { |k| assert props.key?(k), "missing key: #{k}" }
  end

  test "#props returns the correct field values" do
    props = props_for(@payment)
    assert_equal @payment.external_id, props[:external_id]
    assert_equal @payment.displayed_amount, props[:displayed_amount]
    assert_equal @payment.payout_period_end_date, props[:payout_period_end_date]
    assert_equal @payment.created_at, props[:created_at]
    assert_equal @payment.state, props[:state]
    assert_equal @payment.processor, props[:processor]
    assert_equal @payment.processor_fee_cents, props[:processor_fee_cents]
    assert_equal @payment.correlation_id, props[:correlation_id]
  end

  test "#props returns user information when present" do
    user = @payment.user
    assert user
    props = props_for(@payment)
    assert_equal(
      { external_id: user.external_id, name: user.display_name },
      props[:user]
    )
  end

  test "#props returns nil user when payment has no user" do
    @payment.update_column(:user_id, nil)
    @payment.reload
    assert_nil props_for(@payment)[:user]
  end

  test "#props identifies processing state predicates correctly" do
    @payment.update!(state: "processing")
    props = props_for(@payment)
    assert_equal true, props[:processing]
    assert_equal false, props[:failed]
    assert_equal false, props[:cancelled]
    assert_equal false, props[:returned]
    assert_equal false, props[:unclaimed]
    assert_equal true, props[:non_terminal_state]
  end

  test "#props identifies failed state correctly (terminal)" do
    @payment.update!(state: "failed")
    props = props_for(@payment)
    assert_equal true, props[:failed]
    assert_equal false, props[:processing]
    assert_equal false, props[:non_terminal_state]
  end

  test "#props identifies cancelled state" do
    @payment.update!(state: Payment::CANCELLED)
    props = props_for(@payment)
    assert_equal true, props[:cancelled]
    assert_equal false, props[:processing]
  end

  test "#props identifies returned state" do
    @payment.update!(state: "returned")
    props = props_for(@payment)
    assert_equal true, props[:returned]
    assert_equal false, props[:processing]
  end

  test "#props identifies unclaimed state as non-terminal" do
    @payment.update!(state: "unclaimed")
    props = props_for(@payment)
    assert_equal true, props[:unclaimed]
    assert_equal false, props[:processing]
    assert_equal true, props[:non_terminal_state]
  end

  test "#props for PayPal processor exposes PayPal-specific fields" do
    @payment.update!(
      processor: PayoutProcessorType::PAYPAL,
      txn_id: "PAYPAL-TXN-123",
      payment_address: "seller@example.com",
      correlation_id: "CORR-123"
    )
    props = props_for(@payment)
    assert_equal "PAYPAL-TXN-123", props[:txn_id]
    assert_equal "seller@example.com", props[:payment_address]
    assert_equal "CORR-123", props[:correlation_id]
    assert_equal true, props[:is_paypal_processor]
    assert_equal false, props[:is_stripe_processor]
    assert_equal PayoutProcessorType::PAYPAL, props[:processor]
  end

  test "#props for Stripe processor exposes Stripe-specific fields and URLs" do
    @payment.update!(
      processor: PayoutProcessorType::STRIPE,
      stripe_transfer_id: "tr_123456",
      stripe_connect_account_id: "acct_123456"
    )
    props = props_for(@payment)
    assert_equal "tr_123456", props[:stripe_transfer_id]
    assert_equal "acct_123456", props[:stripe_connect_account_id]
    assert_equal StripeUrl.transfer_url("tr_123456", account_id: "acct_123456"), props[:stripe_transfer_url]
    assert_equal StripeUrl.connected_account_url("acct_123456"), props[:stripe_connected_account_url]
    assert_equal true, props[:is_stripe_processor]
    assert_equal false, props[:is_paypal_processor]
  end

  test "#props returns nil for bank_account when payment has no bank account" do
    @payment.update_column(:bank_account_id, nil)
    @payment.reload
    assert_nil props_for(@payment)[:bank_account]
  end
end
