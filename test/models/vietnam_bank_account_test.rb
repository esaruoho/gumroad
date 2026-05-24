require "test_helper"

class VietnamBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    VietnamBankAccount.new({
      user: users(:named_seller),
      account_number: "000123456789",
      account_number_last_four: "6789",
      bank_code: "01101100",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns VN" do
    assert_equal "VN", build.bank_account_type
  end

  test "#country returns VN" do
    assert_equal "VN", build.country
  end

  test "#currency returns vnd" do
    assert_equal "vnd", build.currency
  end

  test "#routing_number returns valid for 8 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "01101100", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_bank_code allows 8 numbers only" do
    assert build(bank_code: "01101100").valid?
    refute build(bank_code: "AAAATWTX").valid?
    refute build(bank_code: "0110110").valid?
    refute build(bank_code: "011011000").valid?
  end
end
