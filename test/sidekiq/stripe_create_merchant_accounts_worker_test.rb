# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/sidekiq/stripe_create_merchant_accounts_worker_spec.rb (78 FB refs, 245 lines).
#
# Blocker for batch 6b-B backfill: `:vcr`-tagged. Each test stages a compliant user
# chain (`create(:user_compliance_info)` + `create(:tos_agreement)` +
# `create(:ach_account)` / `:ach_account_stripe_succeed` + `create(:balance)`) and
# then calls the real `StripeMerchantAccountManager.create_account(user, passphrase: ...)`
# which hits Stripe Connect. Needs VCR cassettes + the full TOS/compliance/bank-account
# fixture roster for multiple sellers — out of scope.
class StripeCreateMerchantAccountsWorkerTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/stripe_create_merchant_accounts_worker_spec.rb — :vcr-tagged; chains user_compliance_info + tos_agreement + ach_account + balance fixtures across multiple sellers, then calls StripeMerchantAccountManager.create_account against real Stripe Connect. Requires Stripe VCR cassettes + compliance/TOS/bank fixture chain. Out of scope."
  end
end
