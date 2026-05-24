# frozen_string_literal: true

require "test_helper"

class TaxjarApiTest < ActiveSupport::TestCase
  test "skipped: VCR-required" do
    skip "TaxjarApi spec is :vcr tagged across ~27 examples and exercises the live Taxjar API (calculate_tax_for_order, create_order_transaction, refund_order_transaction). VCR is not yet wired into Minitest. Covered by RSpec."
  end
end
