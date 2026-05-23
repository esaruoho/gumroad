# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during bulk fixtures-only migration.
# Original: spec/services/order/confirm_service_spec.rb
# Reason: VCR-tagged Stripe SCA flow + MerchantAccount + Order::CreateService/ChargeService
# integration; allow_any_instance_of(Purchase) chains. Migrating requires careful
# stripe-mock setup for SCA + 3DS confirm pathway. Deferred.
class Order::ConfirmServiceTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — VCR Stripe SCA flow + allow_any_instance_of chains" do
    skip "TODO: migrate spec/services/order/confirm_service_spec.rb (VCR Stripe SCA, MerchantAccount, allow_any_instance_of)"
  end
end
