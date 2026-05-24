# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/modules/product/recommendations_spec.rb (13 FactoryBot refs, 119 lines).
#
# Blocker for batch A backfill: the spec is tagged `:elasticsearch_wait_for_refresh`
# and every example builds `create(:product, user: create(:compliant_user), taxonomy: create(:taxonomy))`.
# `compliant_user` is the heaviest factory chain in the codebase (user_compliance_info +
# tos_agreements + merchant_accounts + bank_accounts + user_risk_state transitions),
# and `Product::Recommendations#recommendable_reasons` cascades into
# `user.recommendable_reasons` which checks `compliant?` (touches all of the above)
# plus `sales.counts_towards_volume.exists?` (needs purchases + ES index refresh).
# There is no `:compliant_user` fixture and no `:taxonomy` fixture in `test/fixtures/`
# either — see test/modules/user/recommendations_test.rb which keeps the same skip.
# Real migration requires building both fixture rosters + an ES-refresh harness;
# scope-out of batch A per "fixture-hostile, max 10 iterations" rule.
class ModulesProductRecommendationsTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/modules/product/recommendations_spec.rb — needs :compliant_user + :taxonomy fixture rosters and an ES :elasticsearch_wait_for_refresh harness; covered today by the RSpec integration suite."
  end
end
