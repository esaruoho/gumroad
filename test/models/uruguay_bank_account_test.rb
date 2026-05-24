require "test_helper"

class UruguayBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    UruguayBankAccount.new({
      user: users(:named_seller),
      account_number: "000123456789",
      account_number_last_four: "6789",
      bank_code: "999",
      account_holder_full_name: "John Doe",
    }.merge(attrs))
  end

  test "#bank_account_type returns UY" do
    assert_equal "UY", build.bank_account_type
  end

  test "#country returns UY" do
    assert_equal "UY", build.country
  end

  test "#currency returns uyu" do
    assert_equal Currency::UYU, build.currency
  end

  test "#bank_code returns valid for 3 digits" do
    assert build(bank_number: "123").valid?
    refute build(bank_number: "12").valid?
    refute build(bank_number: "1234").valid?
    refute build(bank_number: "abc").valid?
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build.account_number_visual
  end

  test "#validate_account_number allows 1 to 18 digits" do
    assert build(account_number: "1").valid?
    assert build(account_number: "123456789101").valid?
    refute build(account_number: "1234567891011").valid?
    refute build(account_number: "abc").valid?
  end
end
