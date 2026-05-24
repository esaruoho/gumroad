# frozen_string_literal: true

require "test_helper"

class CreateStripeApplePayDomainWorkerTest < ActiveSupport::TestCase
  test "skipped: VCR-required" do
    skip "CreateStripeApplePayDomainWorker spec uses :vcr; VCR/cassette tooling not yet wired into Minitest. Covered by RSpec."
  end
end
