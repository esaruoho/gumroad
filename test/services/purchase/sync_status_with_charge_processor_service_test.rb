require "test_helper"

# TODO: Migrate from RSpec. 41 FactoryBot refs. Original: spec/services/purchase/sync_status_with_charge_processor_service_spec.rb
# Skip-batched during fixtures-only migration (mig-a) — service specs are Tier 3-4
# (subscription / purchase / Stripe / Elasticsearch / VCR chains) and require
# manual rewrite with fixtures post-deadline.
class Purchase::SyncStatusWithChargeProcessorServiceTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/services/purchase/sync_status_with_charge_processor_service_spec.rb (41 FactoryBot refs)"
  end
end
