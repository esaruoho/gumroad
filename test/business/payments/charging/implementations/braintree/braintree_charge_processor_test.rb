# frozen_string_literal: true

require "test_helper"

class BraintreeChargeProcessorTest < ActiveSupport::TestCase
  test "skipped: VCR-required" do
    skip "BraintreeChargeProcessor spec is :vcr tagged across the full charge/refund lifecycle (Braintree::Transaction.sale!, refund!, find) against the Braintree sandbox via VCR cassettes. VCR is not yet wired into Minitest. Covered by RSpec."
  end
end
