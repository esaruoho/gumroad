require "test_helper"

class MongoliaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    MongoliaBankAccount.new({
      user: users(:named_seller),
      account_number: "000123456789",
      account_number_last_four: "6789",
      bank_code: "AAAAMNUBXXX",
      account_holder_full_name: "Mongolia Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns MN" do
    assert_equal "MN", build.bank_account_type
  end

  test "#country returns MN" do
    assert_equal "MN", build.country
  end

  test "#currency returns mnt" do
    assert_equal "mnt", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAAMNUBXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******2001", build(account_number_last_four: "2001").account_number_visual
  end

  test "#validate_bank_code allows 8 to 11 characters only" do
    assert build(bank_code: "AAAAMNUBXXX").valid?
    assert build(bank_code: "AAAAMNUB").valid?
    assert_not build(bank_code: "AAAAMNUBXXXX").valid?
    assert_not build(bank_code: "AAAAMNU").valid?
  end

  test "#validate_account_number validates account number format" do
    ba = build
    ba.account_number = "000123456789"
    ba.account_number_last_four = "6789"
    assert ba.valid?

    ba.account_number = "1234"
    ba.account_number_last_four = "1234"
    assert ba.valid?

    ba.account_number = "1234567890123456"
    ba.account_number_last_four = "3456"
    assert_not ba.valid?
  end
end
