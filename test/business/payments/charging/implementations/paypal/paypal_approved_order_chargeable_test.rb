# frozen_string_literal: true

require "test_helper"

class PaypalApprovedOrderChargeableTest < ActiveSupport::TestCase
  setup do
    @chargeable = PaypalApprovedOrderChargeable.new("9J862133JL8076730", "paypal-gr-integspecs@gumroad.com", "US")
  end

  test "returns customer paypal email for #email, paypal order id for #fingerprint, and nil #last4" do
    assert_equal "9J862133JL8076730", @chargeable.fingerprint
    assert_equal "paypal-gr-integspecs@gumroad.com", @chargeable.email
    assert_nil @chargeable.last4
  end

  test "returns customer paypal email for #visual, and nil for #number_length, #expiry_month and #expiry_year" do
    assert_equal "paypal-gr-integspecs@gumroad.com", @chargeable.visual
    assert_nil @chargeable.number_length
    assert_nil @chargeable.expiry_month
    assert_nil @chargeable.expiry_year
  end

  test "returns correct country and nil #zip_code" do
    assert_nil @chargeable.zip_code
    assert_equal "US", @chargeable.country
  end

  test "returns nil for #reusable_token!" do
    assert_nil @chargeable.reusable_token!(123)
  end

  test "returns paypal for #charge_processor_id" do
    assert_equal "paypal", @chargeable.charge_processor_id
  end
end
