require "test_helper"

class JordanBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    JordanBankAccount.new({
      user: users(:named_seller),
      account_number: "JO32ABCJ0010123456789012345678",
      account_number_last_four: "5678",
      bank_code: "AAAAJOJOXXX",
      account_holder_full_name: "Jordanian Creator I",
    }.merge(attrs))
  end

  test "#bank_account_type returns JO" do
    assert_equal "JO", build.bank_account_type
  end

  test "#country returns JO" do
    assert_equal "JO", build.country
  end

  test "#currency returns jod" do
    assert_equal "jod", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAAJOJOXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "JO******5678", build(account_number_last_four: "5678").account_number_visual
  end
end
