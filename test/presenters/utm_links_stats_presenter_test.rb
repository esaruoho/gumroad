# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during fixtures-only migration.
# Requires utm_links + utm_link_driven_sales + utm_link_visits fixtures (none
# exist) and exercises `seller.utm_links` joined with `successful_purchases`,
# i.e. a Purchase scope that depends on purchase state machine flags
# (test_purchase / failed_purchase distinctions). Tier 3 — three new fixture
# tables plus state-correct purchases fixture rows for each variant.
#
# Original spec: spec/presenters/utm_links_stats_presenter_spec.rb (deleted)
class UtmLinksStatsPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — needs utm_links/utm_link_driven_sales fixtures + purchase state variants" do
    skip "TODO: migrate spec/presenters/utm_links_stats_presenter_spec.rb (16 FB refs, utm_links/utm_link_driven_sales/utm_link_visits + purchase state variants)"
  end
end
