require "test_helper"

class BeninBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    BeninBankAccount.new({
      user: users(:named_seller),
      account_number: "BJ66BJ0610100100144390000769",
      account_number_last_four: "0769",
      account_holder_full_name: "Benin Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns BJ" do
    assert_equal "BJ", build.bank_account_type
  end

  test "#country returns BJ" do
    assert_equal "BJ", build.country
  end

  test "#currency returns xof" do
    assert_equal "xof", build.currency
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "BJ******0769", build(account_number_last_four: "0769").account_number_visual
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end

  test "#validate_account_number allows records that match the required account number regex" do
    assert build.valid?
    assert build(account_number: "BJ66AJ06101001001KR390000760").valid?

    ba = build(account_number: "FR66BJ0610100100144390000769")
    assert_not ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

    ba = build(account_number: "BJ66BJ061010010014439000076")
    assert_not ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

    ba = build(account_number: "BJ66BJ06101001001443900007690")
    assert_not ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

    ba = build(account_number: "9066890610100100144390000769")
    assert_not ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
  end
end
