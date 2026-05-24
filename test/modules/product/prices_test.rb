# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/modules/product/prices_spec.rb (65 FactoryBot refs, 780 lines).
#
# Blocker for batch A backfill: second-largest concern spec in the codebase
# after with_product_files_spec.rb. Tests `Product::Prices` price calculation
# across single-purchase / recurring / tiered / PWYW / offer-coded / variant /
# multi-currency products. Every branch needs distinct factory shapes:
# `create(:membership_product_with_preset_tiered_pricing, ...)`,
# `create(:product, :recurring_billing, ...)`, offer_codes, variants, prices
# in multiple currencies. Skill rule P-M3: >40 FB → skip-batch; this is at 65.
# `test/fixtures/prices.yml` is sparse and there are no membership/tiered/PWYW
# product fixtures. Out of scope for batch A.
class ModulesProductPricesTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/modules/product/prices_spec.rb — 65 FactoryBot refs / 780 lines (skill P-M3 skip-batch). Needs full tiered/PWYW/recurring/variant/offer-code/multi-currency product+price fixture rosters."
  end
end
