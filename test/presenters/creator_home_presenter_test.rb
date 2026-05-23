require "test_helper"

# TODO: Migrate from RSpec. This spec was skip-batched during the bulk
# fixtures-only migration because it has 43 FactoryBot/create references
# (and/or fixture-hostile dependencies) — too coupled to convert mechanically.
# Reason: Pre-authorized skip-batch (>40 FactoryBot refs) plus ES-chain dependency (User::Stats/revenue_as_seller).
#
# Original spec: spec/presenters/creator_home_presenter_spec.rb (deleted in this commit; see git history)
class CreatorHomePresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/presenters/creator_home_presenter_spec.rb (43 FactoryBot refs)"
  end
end
