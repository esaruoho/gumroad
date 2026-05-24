# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during fixtures-only controller migration.
# Original: spec/controllers/purchases_controller_spec.rb (137 FactoryBot refs).
# Blockers: monolithic checkout/charge spec — heavy Stripe/Braintree mocking, recaptcha
# stubs, dynamic VCR cassettes, recurring billing flows, anti-fraud risk service,
# offer codes, gift purchases, preorders, subscriptions, mobile_token export. Cannot
# be migrated mechanically; requires a manual rewrite split into multiple files.
class PurchasesControllerTest < ActiveSupport::TestCase
  test "TODO: migrate spec/controllers/purchases_controller_spec.rb — fixture-hostile (Stripe + Braintree + recaptcha + VCR)" do
    skip "TODO: migrate spec/controllers/purchases_controller_spec.rb (137 FB refs) — needs Stripe/Braintree mocking + VCR + recurring billing + risk service rewrite"
  end
end
