# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during fixtures-only migration.
# Requires `seller_post`, `workflow_installment`, `product_workflow` factories;
# no installments/workflows fixtures exist in test/fixtures/ for these shapes,
# and reusing :named_seller collides with the documented
# `installments(:no_audience_post)` seller-leak pitfall (gumroad-fixtures-migration
# skill). Needs an isolated seller fixture + 3 new fixture tables — out of
# scope for a single tick.
#
# Original spec: spec/presenters/paginated_product_posts_presenter_spec.rb (deleted)
class PaginatedProductPostsPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — needs isolated seller + workflow/installment fixtures" do
    skip "TODO: migrate spec/presenters/paginated_product_posts_presenter_spec.rb (3 FB refs, needs workflows/installments fixtures + isolated seller)"
  end
end
