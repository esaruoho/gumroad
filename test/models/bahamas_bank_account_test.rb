require "test_helper"

class BahamasBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    BahamasBankAccount.new({
      user: users(:named_seller),
      account_number: "0001234",
      account_number_last_four: "1234",
      bank_code: "AAAABSNSXXX",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns BS" do
    assert_equal "BS", build.bank_account_type
  end

  test "#country returns BS" do
    assert_equal "BS", build.country
  end

  test "#currency returns bsd" do
    assert_equal "bsd", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAABSNSXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******1234", build(account_number_last_four: "1234").account_number_visual
  end

  test "#validate_bank_code allows 8 to 11 characters only" do
    assert build(bank_code: "AAAABSNS").valid?
    assert build(bank_code: "AAAABSNSXXX").valid?
    assert_not build(bank_code: "AAAABS").valid?
    assert_not build(bank_code: "AAAABSNSXXXX").valid?
  end
end
