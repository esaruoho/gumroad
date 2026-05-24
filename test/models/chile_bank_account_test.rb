require "test_helper"

class ChileBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    ChileBankAccount.new({
      user: users(:named_seller),
      account_number: "000123456789",
      account_number_last_four: "6789",
      bank_code: "999",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns Chile" do
    assert_equal "CL", build.bank_account_type
  end

  test "#country returns CL" do
    assert_equal "CL", build.country
  end

  test "#currency returns clp" do
    assert_equal "clp", build.currency
  end

  test "#routing_number returns valid for 3 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "999", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_bank_code allows 3 numeric characters only" do
    assert build(bank_code: "123").valid?
    assert_not build(bank_code: "12").valid?
    assert_not build(bank_code: "1234").valid?
    assert_not build(bank_code: "12A").valid?
    assert_not build(bank_code: "12@").valid?
  end

  test "account types allows checking account types" do
    ba = build(account_type: ChileBankAccount::AccountType::CHECKING)
    assert ba.valid?
    assert_equal ChileBankAccount::AccountType::CHECKING, ba.account_type
  end

  test "account types allows savings account types" do
    ba = build(account_type: ChileBankAccount::AccountType::SAVINGS)
    assert ba.valid?
    assert_equal ChileBankAccount::AccountType::SAVINGS, ba.account_type
  end

  test "account types invalidates other account types" do
    ba = build(account_type: "evil_account_type")
    assert_not ba.valid?
  end

  test "account types translates a nil account type to the default (checking)" do
    ba = build(account_type: nil)
    assert ba.valid?
    assert_equal ChileBankAccount::AccountType::CHECKING, ba.account_type
  end
end
