require "test_helper"

class BotswanaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    BotswanaBankAccount.new({
      user: users(:named_seller),
      account_number: "000123456789",
      account_number_last_four: "6789",
      bank_code: "AAAABWBWXXX",
      account_holder_full_name: "Botswana Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns BW" do
    assert_equal "BW", build.bank_account_type
  end

  test "#country returns BW" do
    assert_equal "BW", build.country
  end

  test "#currency returns bwp" do
    assert_equal "bwp", build.currency
  end

  test "#routing_number returns valid for 8 to 11 characters" do
    assert_not build(bank_code: "AAAAOMO").valid?
    assert build(bank_code: "AAAAOMOM").valid?
    assert build(bank_code: "AAAAOMOMX").valid?
    assert build(bank_code: "AAAAOMOMXX").valid?
    assert build(bank_code: "AAAAOMOMXXX").valid?
    assert_not build(bank_code: "AAAAOMOMXXXX").valid?
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "123456").valid?
      assert build(account_number: "000123456789").valid?
      assert build(account_number: "1234567890123456").valid?
      assert build(account_number: "ABCDEFGHIJKLMNOP").valid?
    end
  end

  test "#validate_account_number rejects records that do not match the required account number regex" do
    Rails.env.stub(:production?, true) do
      ba = build(account_number: "00012345678910111")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "ABCDEFGHIJKLMNOPQ")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "BW123456789012345")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
