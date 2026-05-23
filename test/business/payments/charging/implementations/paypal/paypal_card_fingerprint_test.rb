# frozen_string_literal: true

require "test_helper"

class PaypalCardFingerprintTest < ActiveSupport::TestCase
  test "forms a fingerprint using the email when valid" do
    assert_equal "paypal_jane.doe@gmail.com", PaypalCardFingerprint.build_paypal_fingerprint("jane.doe@gmail.com")
  end

  test "forms a fingerprint using the email when invalidly formed" do
    assert_equal "paypal_jane.doe", PaypalCardFingerprint.build_paypal_fingerprint("jane.doe")
  end

  test "returns nil for whitespace email" do
    assert_nil PaypalCardFingerprint.build_paypal_fingerprint("  ")
  end

  test "returns nil for nil email" do
    assert_nil PaypalCardFingerprint.build_paypal_fingerprint(nil)
  end
end
