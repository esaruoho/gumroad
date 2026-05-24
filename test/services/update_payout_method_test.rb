# frozen_string_literal: true

require "test_helper"

class UpdatePayoutMethodTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/update_payout_method_spec.rb
  # Blocker: Japan kana validators + UserComplianceInfo country switches + BankAccount type swap + HandleNewBankAccountWorker enqueues + Stripe sync. Requires japan_bank_account / canadian_bank_account / paypal_payment_address fixtures + Stripe Customer.update VCR.
  test "TODO: migrate spec/services/update_payout_method_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
