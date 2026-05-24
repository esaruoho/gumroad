require "test_helper"

class AngolaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    AngolaBankAccount.new({
      user: users(:named_seller),
      account_number: "AO06004400006729503010102",
      account_number_last_four: "0102",
      bank_code: "AAAAAOAOXXX",
      account_holder_full_name: "Angola Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns AO" do
    assert_equal "AO", build.bank_account_type
  end

  test "#country returns AO" do
    assert_equal "AO", build.country
  end

  test "#currency returns aoa" do
    assert_equal "aoa", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAAAOAOXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "AO******0102", build(account_number_last_four: "0102").account_number_visual
  end

  test "#validate_bank_code allows 8 to 11 characters only" do
    assert build(bank_code: "AAAAAOAOXXX").valid?
    assert build(bank_code: "AAAAAOAO").valid?
    assert_not build(bank_code: "AAAAAOA").valid?
    assert_not build(bank_code: "AAAAAOAOXXXX").valid?
  end
end
