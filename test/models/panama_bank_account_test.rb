require "test_helper"

class PanamaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    PanamaBankAccount.new({
      user: users(:named_seller),
      bank_number: "AAAAPAPAXXX",
      account_number: "000123456789",
      account_number_last_four: "6789",
      account_holder_full_name: "Chuck Bartowski",
    }.merge(attrs))
  end

  test "#bank_account_type returns PA" do
    assert_equal "PA", build.bank_account_type
  end

  test "#country returns PA" do
    assert_equal "PA", build.country
  end

  test "#currency returns usd" do
    assert_equal "usd", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAAPAPAXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_bank_code allows 11 characters only" do
    assert build(bank_number: "AAAAPAPAXXX").valid?
    assert_not build(bank_number: "AAAAPAPAXX").valid?
    assert_not build(bank_number: "AAAAPAPAXXXX").valid?
  end
end
