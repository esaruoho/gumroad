# frozen_string_literal: true

require "test_helper"

class PaypalChargeableTest < ActiveSupport::TestCase
  setup do
    @paypal_chargeable = PaypalChargeable.new("B-38D505255T217912K", "paypal-gr-integspecs@gumroad.com", "US")
  end

  test "returns customer paypal email for #email, billing agreement id for #fingerprint, and nil #last4" do
    assert_equal "B-38D505255T217912K", @paypal_chargeable.fingerprint
    assert_equal "paypal-gr-integspecs@gumroad.com", @paypal_chargeable.email
    assert_nil @paypal_chargeable.last4
  end

  test "returns customer paypal email for #visual, and nil for #number_length, #expiry_month and #expiry_year" do
    assert_equal "paypal-gr-integspecs@gumroad.com", @paypal_chargeable.visual
    assert_nil @paypal_chargeable.number_length
    assert_nil @paypal_chargeable.expiry_month
    assert_nil @paypal_chargeable.expiry_year
  end

  test "returns correct country and nil #zip_code" do
    assert_nil @paypal_chargeable.zip_code
    assert_equal "US", @paypal_chargeable.country
  end

  test "returns billing agreement id for #reusable_token!" do
    assert_equal "B-38D505255T217912K", @paypal_chargeable.reusable_token!(nil)
  end

  test "returns paypal for #charge_processor_id" do
    assert_equal "paypal", @paypal_chargeable.charge_processor_id
  end
end
