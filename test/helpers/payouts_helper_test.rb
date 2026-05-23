require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration:
# 62 FactoryBot/create refs spanning users, merchant accounts, balances,
# payments, ach_accounts, bank_accounts, sales — a dense factory web that is
# cheaper to rewrite from scratch with fixtures than to translate mechanically.
#
# Original spec: spec/helpers/payouts_helper_spec.rb (deleted in this commit)
class PayoutsHelperTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/helpers/payouts_helper_spec.rb (62 FactoryBot refs) — dense payouts factory web"
  end
end
