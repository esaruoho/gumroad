require "test_helper"

class TrinidadAndTobagoBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    TrinidadAndTobagoBankAccount.new({
      user: users(:named_seller),
      account_number: "00567890123456789",
      bank_code: "999",
      branch_code: "00001",
      account_number_last_four: "6789",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns TT" do
    assert_equal "TT", build.bank_account_type
  end

  test "#country returns TT" do
    assert_equal "TT", build.country
  end

  test "#currency returns ttd" do
    assert_equal "ttd", build.currency
  end

  test "#routing_number returns valid for 8 digits" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "99900001", ba.routing_number
  end

  test "#account_number_visual returns the visual account number with country code prefixed" do
    assert_equal "******9999", build(account_number_last_four: "9999").account_number_visual
  end

  test "#validate_bank_code allows 3 digits only" do
    assert build(bank_code: "110").valid?
    assert build(bank_code: "123").valid?
    refute build(bank_code: "11").valid?
    refute build(bank_code: "ABC").valid?
  end

  test "#validate_branch_code allows 5 digits only" do
    assert build(branch_code: "11001").valid?
    assert build(branch_code: "12345").valid?
    refute build(branch_code: "110011").valid?
    refute build(branch_code: "ABCDE").valid?
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
  end
end
