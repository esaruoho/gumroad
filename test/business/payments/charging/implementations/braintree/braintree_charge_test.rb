# frozen_string_literal: true

require "test_helper"

class BraintreeChargeTest < ActiveSupport::TestCase
  test "skipped: VCR-required" do
    skip "BraintreeCharge spec is :vcr tagged and exercises Braintree::Transaction.sale!/find against the Braintree sandbox via VCR cassettes. VCR is not yet wired into Minitest. Covered by RSpec."
  end
end
