# frozen_string_literal: true

require "test_helper"

class HandleNewBankAccountWorkerTest < ActiveSupport::TestCase
  setup do
    @bank_account = bank_accounts(:basic_ach_account)
  end

  test "calls StripeMerchantAccountManager.handle_new_bank_account" do
    seen = nil
    StripeMerchantAccountManager.stub(:handle_new_bank_account, ->(ba) { seen = ba; :synced }) do
      HandleNewBankAccountWorker.new.perform(@bank_account.id)
    end
    assert_equal @bank_account.id, seen.id
  end

  test "raises when manager returns :stripe_unknown_error" do
    StripeMerchantAccountManager.stub(:handle_new_bank_account, ->(_ba) { :stripe_unknown_error }) do
      err = assert_raises(RuntimeError) { HandleNewBankAccountWorker.new.perform(@bank_account.id) }
      assert_match(/Stripe bank sync failed/, err.message)
    end
  end

  test "does not raise on classified outcomes" do
    %i[synced noop_metadata_match invalid_account_holder_name invalid_bank_account stripe_invalid_request].each do |outcome|
      StripeMerchantAccountManager.stub(:handle_new_bank_account, ->(_ba) { outcome }) do
        HandleNewBankAccountWorker.new.perform(@bank_account.id)
      end
    end
  end
end
