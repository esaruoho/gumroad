require "test_helper"

class TanzaniaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    TanzaniaBankAccount.new({
      user: users(:named_seller),
      account_number: "0000123456789",
      account_number_last_four: "6789",
      bank_code: "AAAATZTXXXX",
      account_holder_full_name: "Tanzanian Creator I",
    }.merge(attrs))
  end

  test "#bank_account_type returns TZ" do
    assert_equal "TZ", build.bank_account_type
  end

  test "#country returns TZ" do
    assert_equal "TZ", build.country
  end

  test "#currency returns tzs" do
    assert_equal "tzs", build.currency
  end

  test "#routing_number returns valid for 8 to 11 characters" do
    assert build(bank_code: "AAAATZTXXXX").valid?
    assert build(bank_code: "AAAATZTX").valid?
    refute build(bank_code: "AAAATZTXXXXX").valid?
    refute build(bank_code: "AAAATZT").valid?
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "0000123456789").valid?
      assert build(account_number: "0000123456").valid?
      assert build(account_number: "ABC12345678").valid?
      assert build(account_number: "0001234567ABCD").valid?

      ba = build(account_number: "000012345")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "000012345678910")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "0001234567ABCDE")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "ABCDE0001234567")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
