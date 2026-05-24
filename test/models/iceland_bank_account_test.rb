require "test_helper"

class IcelandBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    IcelandBankAccount.new({
      user: users(:named_seller),
      account_number: "IS140159260076545510730339",
      account_number_last_four: "0339",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns IS" do
    assert_equal "IS", build.bank_account_type
  end

  test "#country returns IS" do
    assert_equal "IS", build.country
  end

  test "#currency returns eur" do
    assert_equal "eur", build.currency
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "IS******0339", build(account_number_last_four: "0339").account_number_visual
  end

  test "#validate_account_number validates the IBAN format" do
    assert build.valid?, build.errors.full_messages.to_sentence
    assert_not build(account_number: "IS1401592600765455107303").valid?
    assert_not build(account_number: "IS14015926007654551073033911").valid?
  end
end
