require "test_helper"

class KazakhstanBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    KazakhstanBankAccount.new({
      user: users(:named_seller),
      account_number: "KZ221251234567890123",
      account_number_last_four: "0123",
      bank_code: "AAAAKZKZXXX",
      account_holder_full_name: "Kaz creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns KZ" do
    assert_equal "KZ", build.bank_account_type
  end

  test "#country returns KZ" do
    assert_equal "KZ", build.country
  end

  test "#currency returns kzt" do
    assert_equal "kzt", build.currency
  end

  test "#routing_number returns valid for 8 to 11 characters" do
    assert build(bank_code: "AAAAKZKZ").valid?
    assert build(bank_code: "AAAAKZKZX").valid?
    assert build(bank_code: "AAAAKZKZXX").valid?
    assert build(bank_code: "AAAAKZKZXXX").valid?
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "KZ******0123", build(account_number_last_four: "0123").account_number_visual
  end
end
