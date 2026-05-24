require "test_helper"

class ThailandBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    ThailandBankAccount.new({
      user: users(:named_seller),
      account_number: "000123456789",
      bank_code: "999",
      account_number_last_four: "6789",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns TH" do
    assert_equal "TH", build.bank_account_type
  end

  test "#country returns TH" do
    assert_equal "TH", build.country
  end

  test "#currency returns thb" do
    assert_equal "thb", build.currency
  end

  test "#routing_number returns valid for 3 digits" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "999", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_bank_code allows 3 digits only" do
    assert build(bank_code: "111").valid?
    assert build(bank_code: "999").valid?
    refute build(bank_code: "ABCD").valid?
    refute build(bank_code: "1234").valid?
  end

  test "#validate_account_number allows records that match the required account number regex" do
    assert build(account_number: "000123456789").valid?
    assert build(account_number: "123456789").valid?
    assert build(account_number: "123456789012345").valid?

    ba = build(account_number: "ABCDEFGHIJKL")
    refute ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

    ba = build(account_number: "8937040044053201300000")
    refute ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

    ba = build(account_number: "12345")
    refute ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
  end
end
