require "test_helper"

class CambodiaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    CambodiaBankAccount.new({
      user: users(:named_seller),
      bank_code: "AAAAKHKHXXX",
      account_number: "000123456789",
      account_number_last_four: "6789",
      account_holder_full_name: "Cambodian Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns KH" do
    assert_equal "KH", build.bank_account_type
  end

  test "#country returns KH" do
    assert_equal "KH", build.country
  end

  test "#currency returns khr" do
    assert_equal "khr", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAAKHKHXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    ba = build(account_number: "000123456789", account_number_last_four: "6789")
    assert_equal "******6789", ba.account_number_visual
  end

  test "#validate_bank_code allows 8 to 11 characters only" do
    assert build(bank_code: "AAAAKHKHXXX").valid?
    assert build(bank_code: "AAAAKHKH").valid?
    assert_not build(bank_code: "AAAAKHKHXXXX").valid?
    assert_not build(bank_code: "AAAAKHK").valid?
  end

  test "#validate_account_number validates account number format" do
    ba = build
    ba.account_number = "000123456789"
    ba.account_number_last_four = "6789"
    assert ba.valid?

    ba.account_number = "00012"
    ba.account_number_last_four = "0012"
    assert ba.valid?

    ba.account_number = "1234"
    ba.account_number_last_four = "1234"
    assert_not ba.valid?

    ba.account_number = "1234567890123456"
    ba.account_number_last_four = "3456"
    assert_not ba.valid?
  end
end
