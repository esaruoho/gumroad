# frozen_string_literal: true

require "test_helper"

class BraintreeChargeableTransientCustomerTest < ActiveSupport::TestCase
  test "skipped: VCR-required" do
    skip "BraintreeChargeableTransientCustomer spec is :vcr tagged and exercises tokenize_nonce_to_transient_customer / from_transient_customer_store_key against Braintree sandbox via VCR cassettes (includes Timecop and Redis cache). VCR is not yet wired into Minitest. Covered by RSpec."
  end
end
