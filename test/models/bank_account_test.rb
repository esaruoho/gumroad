# frozen_string_literal: true

require "test_helper"

class BankAccountTest < ActiveSupport::TestCase
  test "account_number_decrypted returns the decrypted account number" do
    # `build(:australian_bank_account)` factory equivalent.
    user = users(:named_seller)
    australian_bank_account = AustralianBankAccount.new(
      user: user,
      account_number: "1234567",
      bsb_number: "062111",
      account_number_last_four: "4567",
      account_holder_full_name: "Gumbot Gumstein I"
    )
    assert_equal "1234567", australian_bank_account.send(:account_number_decrypted)
  end

  # ---- #supports_instant_payouts? ----

  test "supports_instant_payouts? returns false when stripe connect and external account IDs are not present" do
    bank_account = bank_accounts(:basic_ach_account)
    assert_equal false, bank_account.supports_instant_payouts?
  end

  test "supports_instant_payouts? returns true when external account supports instant payouts" do
    bank_account = bank_accounts(:basic_ach_account)
    bank_account.update_columns(
      stripe_connect_account_id: "acct_123",
      stripe_bank_account_id: "ba_456"
    )
    external_account = Struct.new(:available_payout_methods).new(["instant"])
    Stripe::Account.stub(:retrieve_external_account, ->(acct, ext) {
      assert_equal "acct_123", acct
      assert_equal "ba_456", ext
      external_account
    }) do
      assert_equal true, bank_account.supports_instant_payouts?
    end
  end

  test "supports_instant_payouts? returns false when external account does not support instant payouts" do
    bank_account = bank_accounts(:basic_ach_account)
    bank_account.update_columns(stripe_connect_account_id: "acct_123", stripe_bank_account_id: "ba_456")
    external_account = Struct.new(:available_payout_methods).new(["standard"])
    Stripe::Account.stub(:retrieve_external_account, ->(*) { external_account }) do
      assert_equal false, bank_account.supports_instant_payouts?
    end
  end

  test "supports_instant_payouts? returns false when stripe API call fails" do
    bank_account = bank_accounts(:basic_ach_account)
    bank_account.update_columns(stripe_connect_account_id: "acct_123", stripe_bank_account_id: "ba_456")
    Stripe::Account.stub(:retrieve_external_account, ->(*) { raise Stripe::StripeError.new }) do
      assert_equal false, bank_account.supports_instant_payouts?
    end
  end

  test "supports_instant_payouts? notifies the error tracker when stripe API call fails" do
    bank_account = bank_accounts(:basic_ach_account)
    bank_account.update_columns(stripe_connect_account_id: "acct_123", stripe_bank_account_id: "ba_456")
    notified = []
    Stripe::Account.stub(:retrieve_external_account, ->(*) { raise Stripe::StripeError.new }) do
      ErrorNotifier.stub(:notify, ->(*args, **kwargs) { notified << [args, kwargs] }) do
        bank_account.supports_instant_payouts?
      end
    end
    assert_equal 1, notified.size
  end

  test "supports_instant_payouts? returns false when stripe says the bank account has been deleted" do
    bank_account = bank_accounts(:basic_ach_account)
    bank_account.update_columns(stripe_connect_account_id: "acct_123", stripe_bank_account_id: "ba_456")
    err = Stripe::InvalidRequestError.new(
      "The bank account ba_xxx has been deleted and can no longer be used.",
      "external_account"
    )
    Stripe::Account.stub(:retrieve_external_account, ->(*) { raise err }) do
      assert_equal false, bank_account.supports_instant_payouts?
    end
  end

  test "supports_instant_payouts? does not notify the error tracker when stripe says the bank account has been deleted" do
    bank_account = bank_accounts(:basic_ach_account)
    bank_account.update_columns(stripe_connect_account_id: "acct_123", stripe_bank_account_id: "ba_456")
    err = Stripe::InvalidRequestError.new(
      "The bank account ba_xxx has been deleted and can no longer be used.",
      "external_account"
    )
    notified = []
    Stripe::Account.stub(:retrieve_external_account, ->(*) { raise err }) do
      ErrorNotifier.stub(:notify, ->(*args, **kwargs) { notified << [args, kwargs] }) do
        bank_account.supports_instant_payouts?
      end
    end
    assert_empty notified
  end
end
