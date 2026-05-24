# frozen_string_literal: true

require "test_helper"

class AdminSearchServiceTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/admin_search_service_spec.rb
  # Blocker: 47 FactoryBot refs across purchase/gift/links/users. Heavy create_list + searches; service walks AR scopes that overlap with the global purchases fixture (43 rows) — assertion deltas non-mechanical.
  test "TODO: migrate spec/services/admin_search_service_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
