# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/modules/purchase/risk_spec.rb (57 FactoryBot refs, 444 lines).
#
# Blocker for batch A backfill: tests `Purchase::Risk#check_for_fraud` end-to-end.
# Every example builds a fresh `create(:product)` + `create(:purchase, link: product, ...)`
# and exercises a different fraud signal (chargeback by email/guid, IP block list,
# fraudulent_creator suspensions, BlockedObject lookups, BIN block lists, country
# mismatch). Skill rule P-M3: >40 FB → skip-batch; this is well past that at 57 refs
# and 444 lines. Also depends on `Feature.activate(:purchase_check_for_fraudulent_ips)`
# global toggle and BlockedObject fixture rows that don't exist in the Minitest lane.
# Out of scope for batch A.
class ModulesPurchaseRiskTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/modules/purchase/risk_spec.rb — 57 FactoryBot refs / 444 lines (skill P-M3 skip-batch). Needs BlockedObject fixture roster + per-test Feature toggle harness."
  end
end
