# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/modules/purchase/reviews_spec.rb (44 FactoryBot refs, 309 lines).
#
# Blocker for batch A backfill: tests `Purchase::Reviews#allows_review_to_be_counted?`,
# `original_product_review`, video-review attach paths. Every example combines
# `create(:purchase, :with_review, ...)` (which builds Purchase + ProductReview +
# ProductReviewStat + ProductReviewVideo), refunds/disputes, and subscription
# upgrades. Skill rule P-M3: >40 FB refs → skip-batch by default; this one is
# right at 44. `test/fixtures/product_reviews.yml` has 2 rows and
# `product_review_stats.yml` has 1; the spec needs at least a dozen distinct
# review-on-purchase shapes (with/without video, refunded, disputed, upgraded
# subscription paths). Out of scope for batch A.
class ModulesPurchaseReviewsTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/modules/purchase/reviews_spec.rb — 44 FactoryBot refs / 309 lines, needs ProductReview + ProductReviewStat + ProductReviewVideo + subscription-upgrade fixture chains (skill P-M3 skip-batch threshold)."
  end
end
