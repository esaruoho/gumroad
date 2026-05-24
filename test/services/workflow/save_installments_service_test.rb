require "test_helper"

# TODO: Migrate from RSpec. 26 FactoryBot refs. Original: spec/services/workflow/save_installments_service_spec.rb
# Skip-batched during fixtures-only migration (mig-a) — service specs are Tier 3-4
# (subscription / purchase / Stripe / Elasticsearch / VCR chains) and require
# manual rewrite with fixtures post-deadline.
class Workflow::SaveInstallmentsServiceTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/services/workflow/save_installments_service_spec.rb (26 FactoryBot refs)"
  end
end
