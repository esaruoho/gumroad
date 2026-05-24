require "test_helper"

class BangladeshBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    BangladeshBankAccount.new({
      user: users(:named_seller),
      account_number: "0000123456789",
      account_number_last_four: "6789",
      bank_code: "110000000",
      account_holder_full_name: "Bangladesh Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns BD" do
    assert_equal "BD", build.bank_account_type
  end

  test "#country returns BD" do
    assert_equal "BD", build.country
  end

  test "#currency returns bdt" do
    assert_equal "bdt", build.currency
  end

  test "#routing_number returns valid for 9 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "110000000", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    assert build.valid?
    assert build(account_number: "0000123456789").valid?
    assert build(account_number: "00001234567891011").valid?

    ba = build(account_number: "000012345678")
    assert_not ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

    ba = build(account_number: "0000123456789101112")
    assert_not ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

    ba = build(account_number: "BD00123456789101112")
    assert_not ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

    ba = build(account_number: "BDABC")
    assert_not ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
  end
end
