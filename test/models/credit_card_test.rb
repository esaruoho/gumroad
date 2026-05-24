# frozen_string_literal: true

require "test_helper"

# Skip-stub: spec/models/credit_card_spec.rb
# Reason: requires :vcr cassettes + Stripe chargeable factory + StripePaymentMethodHelper +
# Braintree/Paypal charge processor stubs. VCR cassettes and the chargeable factory chain don't have
# a clean Minitest port; full Stripe integration is fixture-hostile per skip-batch policy.
# Original spec: spec/models/credit_card_spec.rb
class CreditCardTest < ActiveSupport::TestCase
  test "skipped: VCR + chargeable factory + Stripe integration" do
    skip "TODO: migrate spec/models/credit_card_spec.rb — :vcr cassettes + Stripe/Braintree/Paypal chargeable factory chain. Covered by RSpec."
  end
end
