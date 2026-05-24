# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only
# migration. Requires multiple net-new fixture tables:
#   - balances.yml (Balance#amount_cents, links Purchase#purchase_success_balance)
#   - ach_accounts.yml + ach_accounts STI (AchAccount < BankAccount)
#   - credits.yml (User credits with balance link)
#   - direct_affiliates.yml + affiliates_links.yml (already exists partially)
#   - collaborators.yml (already exists partially, but needs affiliate_user/seller
#     setup that matches collaborator-credit flow)
#   - affiliate_credits.yml (with affiliate_credit_success_balance link)
# Spec also stubs has_stripe_account_connected? / has_paypal_account_connected?
# and User#total_balance_cents — convertible via Minitest stub helpers.
#
# Original spec: spec/presenters/admin/unreviewed_user_presenter_spec.rb (18 FactoryBot refs)
class Admin::UnreviewedUserPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — needs balances/ach_accounts/credits/affiliate_credits/collaborators fixtures" do
    skip "TODO: migrate spec/presenters/admin/unreviewed_user_presenter_spec.rb (18 FB refs; needs 5+ new fixture tables)"
  end
end
