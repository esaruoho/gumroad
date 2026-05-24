# frozen_string_literal: true

require "test_helper"

class Order::CreateServiceTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/order/create_service_spec.rb
  # Blocker: 24 FactoryBot refs across order/line_item/products/offer_codes/affiliates + Order::CreateService.perform mutates Purchase state through ChargeService — needs Stripe + multi-purchase fixtures.
  test "TODO: migrate spec/services/order/create_service_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
