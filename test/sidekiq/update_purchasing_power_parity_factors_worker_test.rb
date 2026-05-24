# frozen_string_literal: true

require "test_helper"

class UpdatePurchasingPowerParityFactorsWorkerTest < ActiveSupport::TestCase
  test "skipped: requires VCR cassette + PurchasingPowerParityService HTTP call" do
    skip "UpdatePurchasingPowerParityFactorsWorker spec is VCR-driven against a 2025 World Bank cassette; VCR is not configured in Minitest test_helper. Covered by RSpec."
  end
end
