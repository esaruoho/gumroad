# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only
# migration. Requires multiple new fixture tables that don't yet exist
# in test/fixtures/:
#   - payments.yml (with paypal/stripe variants, state-trait permutations
#     covering processing/cancelled/returned/failed/unclaimed, txn_id, etc.)
#   - bank_accounts.yml (for the bank_account association)
#   - The Payment#split_payments_info / was_created_in_split_mode columns.
# Plus Stripe transfer URL construction (no live calls).
#
# Original spec: spec/presenters/admin/payment_presenter_spec.rb (14 FactoryBot refs)
class Admin::PaymentPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — needs payments.yml + bank_accounts.yml + state variants" do
    skip "TODO: migrate spec/presenters/admin/payment_presenter_spec.rb (14 FB refs; needs payments.yml + bank_accounts.yml + state-trait permutations)"
  end
end
