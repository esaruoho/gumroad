require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during bulk fixtures-only migration.
# Reason: Elasticsearch chain (search/autocomplete) -- 15 FactoryBot/create refs.
# Original spec: spec/presenters/discover/autocomplete_presenter_spec.rb (deleted in this commit; see git history).
class Discover::AutocompletePresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec -- fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/presenters/discover/autocomplete_presenter_spec.rb (15 FactoryBot refs) -- Elasticsearch chain (search/autocomplete)"
  end
end
