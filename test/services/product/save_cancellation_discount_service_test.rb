# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during bulk fixtures-only migration.
# Original: spec/services/product/save_cancellation_discount_service_spec.rb
# Reason: depends on :membership_product_with_preset_tiered_pricing factory which builds
# tier variants + recurring price rows (variant_prices, prices) via save_recurring_prices!
# in an after(:create). Requires hand-building variant_categories/variants/prices/recurring_prices
# fixtures across 4 tables — JSON-column-adjacent multi-row trap. Deferred.
class Product::SaveCancellationDiscountServiceTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — tiered membership pricing factory chain" do
    skip "TODO: migrate spec/services/product/save_cancellation_discount_service_spec.rb (membership_product_with_preset_tiered_pricing multi-table chain)"
  end
end
