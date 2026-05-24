# frozen_string_literal: true

require "test_helper"

class GdprBuyerErasureServiceTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/gdpr_buyer_erasure_service_spec.rb
  # Blocker: 16 FactoryBot refs; iterates a buyer email across 6 user touchpoints (purchases, refunds, comments, subscriptions, followers, audience_members) + sends erasure-confirmation mail. Requires multi-table buyer fixture web.
  test "TODO: migrate spec/services/gdpr_buyer_erasure_service_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
