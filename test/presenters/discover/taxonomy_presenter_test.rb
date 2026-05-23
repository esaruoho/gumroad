# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during fixtures-only migration.
# Taxonomy seed is not loaded in the Minitest CI lane per
# gumroad-fixtures-migration skill pitfall. Presenter relies on the full
# taxonomy hierarchy to build category props; no taxonomies.yml fixture exists.
#
# Original spec: spec/presenters/discover/taxonomy_presenter_spec.rb (deleted)
class Discover::TaxonomyPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — requires taxonomy seed not present in Minitest CI" do
    skip "TODO: migrate spec/presenters/discover/taxonomy_presenter_spec.rb (3 FB refs, Taxonomy seed unavailable)"
  end
end
