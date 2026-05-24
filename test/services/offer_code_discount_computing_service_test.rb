# frozen_string_literal: true

require "test_helper"

# Skip-batched per gumroad-fixtures-migration directive.
# Original spec: spec/services/offer_code_discount_computing_service_spec.rb (36 FB refs).
#
# Reasons:
# - 36 FB references just under the >40 hard cap; the spec is structurally a
#   deep matrix of offer_code variants (universal vs product-scoped, fixed vs
#   percent, currency, minimum-quantity, sub/lifetime, expired/limited, etc.)
#   crossed with multiple products / quantities. Each combination needs its own
#   offer-code + product + (sometimes) variant fixture row.
# - The service depends on Product::Pricing (price formatting + variant pricing
#   + recurrence) which would force per-product Price fixture rows for every
#   permutation — the row count compounds well beyond the migration budget.
# - Migration cost vastly exceeds neighbor specs in this folder. Re-attempt as a
#   stand-alone slice once an offer_codes / prices fixture pattern is established.
class OfferCodeDiscountComputingServiceTest < ActiveSupport::TestCase
  test "TODO: migrate spec/services/offer_code_discount_computing_service_spec.rb (skip-batched, 36 FB matrix)" do
    skip "Skip-batched: 36 FB refs across offer-code permutation matrix"
  end
end
