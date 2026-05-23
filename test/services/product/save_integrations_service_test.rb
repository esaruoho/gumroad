# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during bulk fixtures-only migration.
# Original: spec/services/product/save_integrations_service_spec.rb
# Reason: shared_examples across 4 integration types (circle, discord, zoom, google_calendar) with
# expect_any_instance_of(...).to receive(:disconnect!) chains + WebMock for Discord/Google APIs.
# Migrating needs full Integration STI fixtures + careful method-stub conversion. Deferred.
class Product::SaveIntegrationsServiceTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — Integration STI fixtures + 4 shared_examples + WebMock" do
    skip "TODO: migrate spec/services/product/save_integrations_service_spec.rb (Integration STI + expect_any_instance_of chains)"
  end
end
