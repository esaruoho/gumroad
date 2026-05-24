# frozen_string_literal: true

require "test_helper"

class CreatorAnalytics::ProductPageViewsTest < ActiveSupport::TestCase
  test "TODO: migrate spec/services/creator_analytics/product_page_views_spec.rb" do
    skip "ES aggregation chain — test_helper stubs EsClient to return empty buckets, so ProductPageView.__elasticsearch__.refresh_index! and real aggregations cannot be exercised under Minitest. All 12 tests depend on real ES round-trips."
  end
end
