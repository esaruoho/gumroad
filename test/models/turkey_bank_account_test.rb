require "test_helper"

class TurkeyBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    TurkeyBankAccount.new({
      user: users(:named_seller),
      account_number: "TR320010009999901234567890",
      account_number_last_four: "7890",
      bank_code: "ADABTRIS",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns TR" do
    assert_equal "TR", build.bank_account_type
  end

  test "#country returns TR" do
    assert_equal "TR", build.country
  end

  test "#currency returns try" do
    assert_equal "try", build.currency
  end

  test "#routing_number returns valid for 8 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "ADABTRIS", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******1326", build(account_number_last_four: "1326").account_number_visual
  end

  test "#validate_bank_code allows 8 to 11 characters only" do
    assert build(bank_code: "ADABTRISXXX").valid?
    assert build(bank_code: "ADABTRIS").valid?
    refute build(bank_code: "ADABTRI").valid?
    refute build(bank_code: "ADABTRISXXXX").valid?
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "TR320010009999901234567890").valid?

      ba = build(account_number: "TR12345")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "TR3200100099999012345678901")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "TR32001000999990123456789")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "TRABCDE")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
