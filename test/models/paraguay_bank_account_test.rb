require "test_helper"

class ParaguayBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    ParaguayBankAccount.new({
      user: users(:named_seller),
      account_number: "0567890123456789",
      account_number_last_four: "6789",
      bank_code: "0",
      account_holder_full_name: "Paraguayan Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns PY" do
    assert_equal "PY", build.bank_account_type
  end

  test "#country returns PY" do
    assert_equal "PY", build.country
  end

  test "#currency returns pyg" do
    assert_equal "pyg", build.currency
  end

  test "#bank_code returns valid for 1 to 2 characters" do
    assert build(bank_code: "12").valid?
    assert build(bank_code: "1").valid?
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "1234567890123456").valid?
      assert build(account_number: "123").valid?

      py = build(account_number: "12345678901234567")
      assert_not py.valid?
      assert_equal "The account number is invalid.", py.errors.full_messages.to_sentence

      py = build(account_number: "ABC123")
      assert_not py.valid?
      assert_equal "The account number is invalid.", py.errors.full_messages.to_sentence
    end
  end
end
