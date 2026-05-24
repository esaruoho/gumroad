# frozen_string_literal: true

require "test_helper"

class BraintreeChargeableNonceTest < ActiveSupport::TestCase
  test "skipped: VCR-required" do
    skip "BraintreeChargeableNonce spec is :vcr tagged and calls #prepare! which hits Braintree API to vault nonces via VCR cassettes. VCR is not yet wired into Minitest. Covered by RSpec."
  end
end
