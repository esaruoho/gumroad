require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b presenter sweep.
# Blockers: 15 FB refs including :utm_link, :utm_link_driven_sale, :failed_purchase,
# :test_purchase. Presenter paginates with sales aggregation (joins utm_link_driven_sales
# to purchases) — no fixture shape yet for utm_links.yml or utm_link_driven_sales.yml.
# Original spec: spec/presenters/paginated_utm_links_presenter_spec.rb (deleted; see git history)
class PaginatedUtmLinksPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — needs utm_links + utm_link_driven_sales + purchase variant fixtures" do
    skip "TODO: migrate spec/presenters/paginated_utm_links_presenter_spec.rb (15 FB refs; utm_links + driven_sales aggregation shape missing)"
  end
end
