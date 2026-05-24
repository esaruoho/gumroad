# frozen_string_literal: true

require "test_helper"

class UpdatePayoutMethodTest < ActiveSupport::TestCase
  test "TODO: migrate spec/services/update_payout_method_spec.rb (5+ bank-account/compliance factories + HandleNewBankAccountWorker Stripe pipeline)" do
    skip "Awaiting fixtures migration: depends on JapanBankAccount/VietnamBankAccount/IndonesiaBankAccount/AchAccount + UserComplianceInfo fixtures and the Stripe-backed HandleNewBankAccountWorker"
  end
end
