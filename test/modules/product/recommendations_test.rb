# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b sweep: spec tagged
# `:elasticsearch_wait_for_refresh` and relies on `create(:compliant_user)`
# (multi-step compliance/merchant_account/bank_account chain) + `create(:taxonomy)`
# + `create(:purchase, :with_review)` — fixture-only conversion is blocked by the
# ES live-index requirement and the compliant_user chain (5+ net-new fixture tables).
# Authorized under ES skip-batch rule.
#
# Original spec: spec/modules/product/recommendations_spec.rb (13 FB refs + ES tag)
class Product::RecommendationsTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — Elasticsearch-bound, requires manual rewrite" do
    skip "TODO: migrate spec/modules/product/recommendations_spec.rb (ES tag, compliant_user + taxonomy chain) — see comment above"
  end
end
