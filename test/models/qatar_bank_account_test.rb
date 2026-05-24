require "test_helper"

class QatarBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    QatarBankAccount.new({
      user: users(:named_seller),
      account_number: "QA87CITI123456789012345678901",
      account_number_last_four: "8901",
      bank_code: "AAAAQAQAXXX",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns QA" do
    assert_equal "QA", build.bank_account_type
  end

  test "#country returns QA" do
    assert_equal "QA", build.country
  end

  test "#currency returns qar" do
    assert_equal "qar", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAAQAQAXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******8901", build(account_number_last_four: "8901").account_number_visual
  end

  test "#validate_bank_code allows 11 characters only" do
    assert build(bank_code: "AAAAQAQAXXX").valid?
    assert_not build(bank_code: "AAAAQAQA").valid?
    assert_not build(bank_code: "AAAAQAQAXXXX").valid?
  end
end
