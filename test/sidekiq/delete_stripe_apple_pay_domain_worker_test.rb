# frozen_string_literal: true

require "test_helper"

class DeleteStripeApplePayDomainWorkerTest < ActiveSupport::TestCase
  test "skipped: VCR-required" do
    skip "DeleteStripeApplePayDomainWorker spec uses :vcr and hits Stripe::ApplePayDomain.create; VCR/cassette tooling not yet wired into Minitest. Covered by RSpec."
  end
end
