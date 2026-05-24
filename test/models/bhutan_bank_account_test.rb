require "test_helper"

class BhutanBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    BhutanBankAccount.new({
      user: users(:named_seller),
      account_number: "0000123456789",
      account_number_last_four: "6789",
      bank_code: "AAAABTBTXXX",
      account_holder_full_name: "Bhutan Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns BT" do
    assert_equal "BT", build.bank_account_type
  end

  test "#country returns BT" do
    assert_equal "BT", build.country
  end

  test "#currency returns btn" do
    assert_equal "btn", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAABTBTXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    assert build.valid?
    assert build(account_number: "0000123456789").valid?
    assert build(account_number: "0").valid?
    assert build(account_number: "00001234567891011").valid?

    ba = build(account_number: "0000123456789101112")
    assert_not ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
  end
end
