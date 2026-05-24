# frozen_string_literal: true

require "test_helper"

class User::RecommendationsTest < ActiveSupport::TestCase
  setup do
    skip "Product::Recommendations spec depends on the :recommendable_user / :compliant_user factory chain (compliance, merchant accounts, bank accounts, Elasticsearch :elasticsearch_wait_for_refresh tag) — too many net-new fixtures for the Minitest CI lane. Covered by RSpec integration."
  end

  test "covered by RSpec lane" do
    flunk "unreachable"
  end
end
