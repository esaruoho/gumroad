# frozen_string_literal: true

require "test_helper"

class NameFieldSearchTest < ActiveSupport::TestCase
  test "skipped: Elasticsearch query path; original spec uses Link.__elasticsearch__ / .import." do
    skip "ES-bound: Product::Searchable name_field_search exercised against live ES cluster only"
  end
end
