# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b sweep.
# 38 FactoryBot refs across 4 distinct `user_with_compliance_info` users, each
# carrying merchant_account + ach_account + multiple balances with hard-coded
# dynamic `payout_date ± N` values; each test mutates `User.holding_balance`
# state. Net-new fixture tables required: ach_accounts, merchant_accounts,
# payments, plus per-test balance rows — over the 5-table threshold and the
# per-test dynamic-date shape defeats static YAML.
#
# Original spec: spec/business/payments/payouts/payout_estimates_spec.rb
class PayoutEstimatesTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — too many net-new fixture tables, requires manual rewrite" do
    skip "TODO: migrate spec/business/payments/payouts/payout_estimates_spec.rb (38 FB refs, 5+ net-new tables)"
  end
end
