# frozen_string_literal: true

require "test_helper"

class PurchaseGiftsTest < ActiveSupport::TestCase
  test "TODO: migrate PurchaseGifts spec" do
    skip "Original spec is a VCR-driven Stripe integration test that drives full purchase processing (chargeable, gifter/giftee state machines, shipping_destinations, Sidekiq job assertions, ContactingCreatorMailer). Needs stripe-mock wiring + fixture-level chargeable plumbing — skip-batch."
  end
end
