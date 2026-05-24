require "test_helper"

# TODO: Migrate from RSpec. This spec was skip-batched during the bulk
# fixtures-only migration. Reason: Multi-table aggregation (affiliates + affiliates_links + products + purchases) plus composed presenter chain — Tier-3 per presenter triage.
#
# Original spec: spec/presenters/affiliates_presenter_spec.rb (deleted in this commit; see git history). FB ref count: 36.
class AffiliatesPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/presenters/affiliates_presenter_spec.rb (36 FactoryBot refs)"
  end
end
