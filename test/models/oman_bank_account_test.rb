require "test_helper"

class OmanBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    OmanBankAccount.new({
      user: users(:named_seller),
      account_number: "000123456789",
      account_number_last_four: "6789",
      bank_code: "AAAAOMOMXXX",
      account_holder_full_name: "Omani Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns OM" do
    assert_equal "OM", build.bank_account_type
  end

  test "#country returns OM" do
    assert_equal "OM", build.country
  end

  test "#currency returns omr" do
    assert_equal "omr", build.currency
  end

  test "#routing_number returns valid for 8 to 11 characters" do
    assert build(bank_code: "AAAAOMOM").valid?
    assert build(bank_code: "AAAAOMOMX").valid?
    assert build(bank_code: "AAAAOMOMXX").valid?
    assert build(bank_code: "AAAAOMOMXXX").valid?
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_account_number allows records that are valid Omani IBANs" do
    Rails.env.stub(:production?, true) do
      assert build(account_number: "OM030001234567890123456").valid?
      assert build(account_number: "OM810180000001299123456").valid?
    end
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "123456").valid?
      assert build(account_number: "000123456789").valid?
      assert build(account_number: "1234567890123456").valid?
    end
  end

  test "#validate_account_number rejects records that are invalid Omani IBANs" do
    Rails.env.stub(:production?, true) do
      om = build(account_number: "OM000000000000000000000")
      assert_not om.valid?
      assert_equal "The account number is invalid.", om.errors.full_messages.to_sentence

      om = build(account_number: "OM060001234567890123456")
      assert_not om.valid?
      assert_equal "The account number is invalid.", om.errors.full_messages.to_sentence

      om = build(account_number: "FR1420041010050500013M02606")
      assert_not om.valid?
      assert_equal "The account number is invalid.", om.errors.full_messages.to_sentence
    end
  end

  test "#validate_account_number rejects records that do not match the required account number regex" do
    Rails.env.stub(:production?, true) do
      om = build(account_number: "12345")
      assert_not om.valid?
      assert_equal "The account number is invalid.", om.errors.full_messages.to_sentence

      om = build(account_number: "12345678901234567")
      assert_not om.valid?
      assert_equal "The account number is invalid.", om.errors.full_messages.to_sentence

      om = build(account_number: "ABCDEF")
      assert_not om.valid?
      assert_equal "The account number is invalid.", om.errors.full_messages.to_sentence
    end
  end
end
