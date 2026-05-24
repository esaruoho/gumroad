# frozen_string_literal: true

require "test_helper"

class FilteredSearchTest < ActiveSupport::TestCase
  test "skipped: Elasticsearch query path; original spec uses Link.__elasticsearch__ / .import. Not stubbable for filter search behavior in unit fixtures." do
    skip "ES-bound: Product::Searchable filtered_search exercised against live ES cluster only"
  end
end
