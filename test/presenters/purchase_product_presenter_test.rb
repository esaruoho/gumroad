require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only
# migration: requires membership_product / product_with_digital_versions
# factories with variant_categories, prices, asset_previews, custom
# attributes, plus :with_review purchase chains that aggregate ratings.
# Heavy multi-table fixture surface (>5 net-new fixture tables) — defer.
#
# Original spec: spec/presenters/purchase_product_presenter_spec.rb
class PurchaseProductPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — multi-table membership/review fixture surface" do
    skip "TODO: migrate spec/presenters/purchase_product_presenter_spec.rb (membership variants + asset_previews + review aggregations)"
  end
end
