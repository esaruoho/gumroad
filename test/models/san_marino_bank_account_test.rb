require "test_helper"

class SanMarinoBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    SanMarinoBankAccount.new({
      user: users(:named_seller),
      account_number: "SM86U0322509800000000270100",
      account_number_last_four: "0100",
      bank_code: "AAAASMSMXXX",
      account_holder_full_name: "San Marino Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns SM" do
    assert_equal "SM", build.bank_account_type
  end

  test "#country returns SM" do
    assert_equal "SM", build.country
  end

  test "#currency returns eur" do
    assert_equal "eur", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAASMSMXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "SM******0100", build(account_number_last_four: "0100").account_number_visual
  end

  test "#validate_bank_code allows 8 to 11 characters only" do
    assert build(bank_code: "AAAASMSMXXX").valid?
    assert build(bank_code: "AAAASMSM").valid?
    assert_not build(bank_code: "AAAASMS").valid?
    assert_not build(bank_code: "AAAASMSMXXXX").valid?
  end
end
