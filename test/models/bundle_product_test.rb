# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. BundleProduct spec (194 LOC, 21 create() refs)
# needs a Bundle (Link with native_type=bundle) + member products + variants
# + product_with_digital_versions factory chains for the standalone_price_cents
# / in_order / cross-seller-validation cases. The `product_with_digital_versions`
# factory creates a Link + 3 Variants in a single call — no fixture
# equivalent, would need ~5 new fixture rows per test. Out of scope for
# mechanical model backfill.
#
# Original spec: spec/models/bundle_product_spec.rb
class BundleProductTest < ActiveSupport::TestCase
  test "TODO: migrate — Bundle + product_with_digital_versions + variants" do
    skip "21 create() refs through Bundle Link + product_with_digital_versions (Link + 3 Variants) + alive_variants + price_difference_cents chain. Out of scope for mechanical model backfill."
  end
end
