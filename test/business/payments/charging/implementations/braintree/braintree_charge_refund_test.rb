# frozen_string_literal: true

require "test_helper"

class BraintreeChargeRefundTest < ActiveSupport::TestCase
  test "skipped: VCR-required" do
    skip "BraintreeChargeRefund spec is :vcr tagged and creates Braintree::Transaction.sale! / .refund! against the Braintree sandbox via VCR cassettes. VCR is not yet wired into Minitest. Covered by RSpec."
  end
end
