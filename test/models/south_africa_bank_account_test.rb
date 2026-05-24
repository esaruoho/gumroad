require "test_helper"

class SouthAfricaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    SouthAfricaBankAccount.new({
      user: users(:named_seller),
      account_number: "000001234",
      account_number_last_four: "0054",
      bank_code: "FIRNZAJJ",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns ZA" do
    assert_equal "ZA", build.bank_account_type
  end

  test "#country returns ZA" do
    assert_equal "ZA", build.country
  end

  test "#currency returns zar" do
    assert_equal "zar", build.currency
  end

  test "#routing_number returns valid for 8 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "FIRNZAJJ", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******1234", build(account_number_last_four: "1234").account_number_visual
  end

  test "#validate_bank_code allows 8 to 11 characters only" do
    assert build(bank_code: "FIRNZAJJ").valid?
    assert build(bank_code: "FIRNZAJJXXX").valid?
    assert_not build(bank_code: "FIRNZAJ").valid?
    assert_not build(bank_code: "FIRNZAJJXXXX").valid?
  end
end
