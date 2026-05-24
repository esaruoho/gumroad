require "test_helper"

class BoliviaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    BoliviaBankAccount.new({
      user: users(:named_seller),
      account_number: "000123456789",
      bank_code: "040",
      account_number_last_four: "6789",
      account_holder_full_name: "Chuck Bartowski",
      state: "unverified",
    }.merge(attrs))
  end

  test "#bank_account_type returns BO" do
    assert_equal "BO", build.bank_account_type
  end

  test "#country returns BO" do
    assert_equal "BO", build.country
  end

  test "#currency returns bob" do
    assert_equal "bob", build.currency
  end

  test "#routing_number returns valid for 3 digits" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "040", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_bank_code allows 1 to 3 digits only" do
    assert build(bank_code: "1").valid?
    assert build(bank_code: "12").valid?
    assert build(bank_code: "123").valid?
    assert_not build(bank_code: "1234").valid?
    assert_not build(bank_code: "a12").valid?
  end

  test "#validate_account_number allows 10 to 15 digits only" do
    assert build(account_number: "1234567890").valid?
    assert build(account_number: "123456789012345").valid?
    assert_not build(account_number: "123456789").valid?
    assert_not build(account_number: "1234567890123456").valid?
    assert_not build(account_number: "12345a7890").valid?
  end
end
