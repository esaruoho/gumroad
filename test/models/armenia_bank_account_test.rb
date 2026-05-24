require "test_helper"

class ArmeniaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    ArmeniaBankAccount.new({
      user: users(:named_seller),
      bank_code: "AAAAAMNNXXX",
      account_number: "00001234567",
      account_number_last_four: "4567",
      account_holder_full_name: "Armenia creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns AM" do
    assert_equal "AM", build.bank_account_type
  end

  test "#country returns AM" do
    assert_equal "AM", build.country
  end

  test "#currency returns amd" do
    assert_equal "amd", build.currency
  end

  test "#routing_number returns valid for 8 to 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAAAMNNXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******4567", build(account_number_last_four: "4567").account_number_visual
  end

  test "#validate_bank_code allows 8 to 11 characters only" do
    assert build(bank_code: "AAAAAMNNXXX").valid?
    assert build(bank_code: "AAAAAMNN").valid?
    assert_not build(bank_code: "AAAAAMNNXXXX").valid?
    assert_not build(bank_code: "AAAAAMN").valid?
  end

  test "#validate_account_number allows 11 to 16 digits only" do
    assert build(account_number: "00001234567").valid?
    assert build(account_number: "0000123456789012").valid?
    assert_not build(account_number: "0000123456").valid?
    assert_not build(account_number: "00001234567890123").valid?
  end
end
