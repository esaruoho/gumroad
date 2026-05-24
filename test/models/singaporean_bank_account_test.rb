require "test_helper"

class SingaporeanBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    SingaporeanBankAccount.new({
      user: users(:named_seller),
      account_number: "000123456",
      branch_code: "000",
      bank_number: "1100",
      account_number_last_four: "3456",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns SG" do
    assert_equal "SG", build.bank_account_type
  end

  test "#country returns SG" do
    assert_equal "SG", build.country
  end

  test "#currency returns sgd" do
    assert_equal "sgd", build.currency
  end

  test "#routing_number returns valid for 7 digits with hyphen after 4" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "1100-000", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******3456", build(account_number_last_four: "3456").account_number_visual
  end

  test "#validate_bank_code allows 4 digits only" do
    assert build(bank_code: "1100").valid?
    assert build(bank_code: "1234").valid?
    assert_not build(bank_code: "110").valid?
    assert_not build(bank_code: "ABCD").valid?
  end

  test "#validate_branch_code allows 3 digits only" do
    assert build(branch_code: "110").valid?
    assert build(branch_code: "123").valid?
    assert_not build(branch_code: "1100").valid?
    assert_not build(branch_code: "ABC").valid?
  end

  test "#validate_account_number allows records that match the required account number regex" do
    assert build(account_number: "000123456").valid?
    assert build(account_number: "1234567890").valid?

    sg = build(account_number: "ABCDEFGHI")
    assert_not sg.valid?
    assert_equal "The account number is invalid.", sg.errors.full_messages.to_sentence

    sg = build(account_number: "8937040044053201300000")
    assert_not sg.valid?
    assert_equal "The account number is invalid.", sg.errors.full_messages.to_sentence

    sg = build(account_number: "CHABCDE")
    assert_not sg.valid?
    assert_equal "The account number is invalid.", sg.errors.full_messages.to_sentence
  end
end
