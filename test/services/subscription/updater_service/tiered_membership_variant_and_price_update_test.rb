require "test_helper"

# TODO: Migrate from RSpec. 4 FactoryBot refs. Original: spec/services/subscription/updater_service/tiered_membership_variant_and_price_update_spec.rb
# Skip-batched during fixtures-only migration (mig-a) — service specs are Tier 3-4
# (subscription / purchase / Stripe / Elasticsearch / VCR chains) and require
# manual rewrite with fixtures post-deadline.
class Subscription::UpdaterService::TieredMembershipVariantAndPriceUpdateTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/services/subscription/updater_service/tiered_membership_variant_and_price_update_spec.rb (4 FactoryBot refs)"
  end
end
