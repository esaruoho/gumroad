# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. This spec was skip-batched during the bulk
# fixtures-only migration because it depends on the Elasticsearch search
# chain (Purchase indexing via `index_model_records(Purchase)` and
# `Product#has_successful_sales?` which queries ES) and AudienceMember
# JSON-detail factory transients — hostile to mechanical fixture conversion.
#
# Original spec: spec/presenters/user_presenter_spec.rb (deleted in this commit; see git history)
class UserPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/presenters/user_presenter_spec.rb (ES-dependent: Purchase indexing, has_successful_sales?)"
  end
end
