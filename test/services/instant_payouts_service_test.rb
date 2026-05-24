# frozen_string_literal: true

require "test_helper"

class InstantPayoutsServiceTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/instant_payouts_service_spec.rb
  # Blocker: 16 FactoryBot refs + VCR + Stripe::Balance/Transfer creates + merchant_account creation via StripeMerchantAccountManager.create_account. Real Stripe Connect flow.
  test "TODO: migrate spec/services/instant_payouts_service_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
