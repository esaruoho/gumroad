# frozen_string_literal: true

require "test_helper"

class UpdateUserCountryTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/update_user_country_spec.rb
  # Blocker: Stripe account + StripeMerchantAccountManager + ach_account_stripe_succeed factory + user_compliance_info + merchant_account chain; service mutates compliance/stripe account state under VCR. Requires stripe-mock harness + full payouts fixture web.
  test "TODO: migrate spec/services/update_user_country_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
