require "test_helper"

class AntiguaAndBarbudaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    AntiguaAndBarbudaBankAccount.new({
      user: users(:named_seller),
      account_number: "000123456789",
      account_number_last_four: "6789",
      bank_code: "AAAAAGAGXYZ",
      account_holder_full_name: "Antigua and Barbuda Creator I",
    }.merge(attrs))
  end

  test "#bank_account_type returns AG" do
    assert_equal "AG", build.bank_account_type
  end

  test "#country returns AG" do
    assert_equal "AG", build.country
  end

  test "#currency returns xcd" do
    assert_equal "xcd", build.currency
  end

  test "#routing_number returns valid for 8 to 11 characters" do
    assert build(bank_code: "AAAAAGAGXYZ").valid?
    assert build(bank_code: "AAAAAGAG").valid?
    assert_not build(bank_code: "AAAAAGAGXYZZ").valid?
    assert_not build(bank_code: "AAAAAGA").valid?
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "000123456789").valid?
      assert build(account_number: "00012345678910111213141516171819").valid?
      assert build(account_number: "ABC12345678910111213141516171819").valid?
      assert build(account_number: "12345678910111213141516171819ABC").valid?

      ba = build(account_number: "000123456789101112131415161718192")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "ABCD12345678910111213141516171819")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "12345678910111213141516171819ABCD")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "AB12345678910111213141516171819CD")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
