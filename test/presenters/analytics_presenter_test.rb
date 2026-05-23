# frozen_string_literal: true

require "test_helper"

class AnalyticsPresenterTest < ActiveSupport::TestCase
  test "page_props returns the correct props" do
    seller = users(:analytics_seller)
    alive = links(:analytics_alive_product)
    deleted_with_sales = links(:analytics_deleted_with_sales_product)

    presenter = AnalyticsPresenter.new(seller:)
    props = presenter.page_props

    assert_equal(
      [
        { id: deleted_with_sales.external_id, alive: false, unique_permalink: deleted_with_sales.unique_permalink, name: deleted_with_sales.name },
        { id: alive.external_id, alive: true, unique_permalink: alive.unique_permalink, name: alive.name }
      ].sort_by { |h| h[:id] },
      props[:products].sort_by { |h| h[:id] }
    )
    assert_equal "US", props[:country_codes]["United States"]
    assert_equal "Alabama", props[:state_names].first
    assert_equal "Other", props[:state_names].last
  end
end
