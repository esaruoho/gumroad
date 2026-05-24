require "test_helper"

class TaiwanBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    TaiwanBankAccount.new({
      user: users(:named_seller),
      account_number: "0001234567",
      account_number_last_four: "4567",
      bank_code: "AAAATWTXXXX",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns TW" do
    assert_equal "TW", build.bank_account_type
  end

  test "#country returns TW" do
    assert_equal "TW", build.country
  end

  test "#currency returns twd" do
    assert_equal "twd", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAATWTXXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******4567", build(account_number_last_four: "4567").account_number_visual
  end

  test "#validate_bank_code allows 8 to 11 characters only" do
    assert build(bank_code: "AAAATWTXXXX").valid?
    assert build(bank_code: "AAAATWTX").valid?
    refute build(bank_code: "AAAATWT").valid?
    refute build(bank_code: "AAAATWTXXXXX").valid?
  end
end
