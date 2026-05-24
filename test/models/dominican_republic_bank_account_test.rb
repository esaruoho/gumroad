require "test_helper"

class DominicanRepublicBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    DominicanRepublicBankAccount.new({
      user: users(:named_seller),
      account_number: "000123456789",
      bank_code: "999",
      account_number_last_four: "6789",
      account_holder_full_name: "Chuck Bartowski",
    }.merge(attrs))
  end

  test "#bank_account_type returns DO" do
    assert_equal "DO", build.bank_account_type
  end

  test "#country returns DO" do
    assert_equal "DO", build.country
  end

  test "#currency returns dop" do
    assert_equal "dop", build.currency
  end

  test "#routing_number returns the bank code" do
    bank_account = build
    assert_equal bank_account.bank_code, bank_account.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build.account_number_visual
  end

  test "#validate_bank_code allows 1 to 3 digits only" do
    assert build(bank_code: "1").valid?
    assert build(bank_code: "12").valid?
    assert build(bank_code: "123").valid?
    assert_not build(bank_code: "1234").valid?
    assert_not build(bank_code: "a12").valid?
  end

  test "#validate_account_number validates the account number format" do
    bank_account = build
    assert bank_account.valid?

    bank_account.account_number = "invalid123"
    assert_not bank_account.valid?
    assert_includes bank_account.errors[:base], "The account number is invalid."

    bank_account.account_number = "12345678901234567890123456789" # 29 digits
    assert_not bank_account.valid?
    assert_includes bank_account.errors[:base], "The account number is invalid."

    bank_account.account_number = "1234567890123456789012345678" # 28 digits
    assert bank_account.valid?
  end
end
