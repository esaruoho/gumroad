# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. This spec was skip-batched during the bulk
# fixtures-only migration: 41 FactoryBot/create refs (above the >40
# pre-authorized skip-batch threshold) covering products, variants,
# offer codes, third-party analytics, purchase indexing and the full
# product props graph — not a mechanical fixture conversion candidate.
#
# Original spec: spec/presenters/product_presenter/product_props_spec.rb (deleted in this commit; see git history)
class ProductPresenter::ProductPropsTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/presenters/product_presenter/product_props_spec.rb (>40 FactoryBot refs, ES/product graph)"
  end
end
