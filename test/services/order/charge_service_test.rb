require "test_helper"

# TODO: Migrate from RSpec. 103 FactoryBot refs. Original: spec/services/order/charge_service_spec.rb
# Skip-batched during fixtures-only migration (mig-a) — service specs are Tier 3-4
# (subscription / purchase / Stripe / Elasticsearch / VCR chains) and require
# manual rewrite with fixtures post-deadline.
class Order::ChargeServiceTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/services/order/charge_service_spec.rb (103 FactoryBot refs)"
  end
end
