# frozen_string_literal: true

require "test_helper"

class UpdateUtmLinkStatsJobTest < ActiveSupport::TestCase
  test "updates the utm_link's stats" do
    utm_link = utm_links(:utm_link_for_named_seller)
    # Touch fixtures to ensure they're loaded.
    utm_link_visits(:visit_one)
    utm_link_visits(:visit_two)
    utm_link_visits(:visit_three)

    UpdateUtmLinkStatsJob.new.perform(utm_link.id)

    utm_link.reload
    assert_equal 3, utm_link.total_clicks
    assert_equal 2, utm_link.unique_clicks
  end
end
