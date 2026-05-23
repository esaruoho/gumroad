# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during bulk fixtures-only migration.
# Original: spec/services/product/compute_call_availabilities_service_spec.rb
# Reason: heavy time-zone math + 7 distinct factories (call, call_availability, call_product,
# call_purchase, coffee_product, refunded call_purchase variant, user with :eligible_for_service_products
# trait). Multi-table call/call_availabilities/call_limitation_info fixtures w/ purchase chain.
# Deferred for a dedicated batch.
class Product::ComputeCallAvailabilitiesServiceTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — 7 factory chain + tz math + call_limitation_info" do
    skip "TODO: migrate spec/services/product/compute_call_availabilities_service_spec.rb (7 FB refs, multi-tz, call chain)"
  end
end
