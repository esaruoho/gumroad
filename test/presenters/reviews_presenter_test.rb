# frozen_string_literal: true

require "test_helper"

# Skip-batched per gumroad-fixtures-migration directive.
# Original spec: spec/presenters/reviews_presenter_spec.rb (21 FB refs).
#
# Reasons:
# - Uses `create(:thumbnail, ...)` twice. Thumbnail relies on ActiveStorage
#   (`has_one_attached :file`) and the presenter asserts `thumbnail.url` — that
#   path requires an attached blob, which the fixtures-only migration cannot
#   reproduce without per-test blob/attach setup (out of scope per skill
#   "Skip-ActiveStorage" rule).
# - Uses `build_list(:product_review, 3) do ... end` with per-element callbacks
#   that mutate `review.purchase.purchaser` and `review.link.user` — equivalent
#   in fixtures requires 3 product_review rows + 3 purchases + 3 links, each
#   wired to a specific seller, plus matching prices. Multi-table fan-out beyond
#   neighbor presenter cost.
# - Deleted product / banned_at / purchase_disabled_at branches additionally
#   need separate product+purchase+review fixtures, multiplying the row count.
class ReviewsPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate spec/presenters/reviews_presenter_spec.rb (skip-batched, AS thumbnails + multi-table reviews matrix)" do
    skip "Skip-batched: thumbnail.url is ActiveStorage-bound; multi-product review fan-out"
  end
end
