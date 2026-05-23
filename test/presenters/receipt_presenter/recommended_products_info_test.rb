require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration —
# recommended-products presenter depends on Elasticsearch (RecommendedProducts /
# Link.import / search aggregations), which is documented skip-batch territory.
#
# Original spec: spec/presenters/receipt_presenter/recommended_products_info_spec.rb (11 FB refs)
class ReceiptPresenter::RecommendedProductsInfoTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — Elasticsearch-coupled, requires manual rewrite" do
    skip "TODO: migrate spec/presenters/receipt_presenter/recommended_products_info_spec.rb (11 FB refs, ES coupled)"
  end
end
