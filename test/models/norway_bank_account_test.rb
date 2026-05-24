require "test_helper"

class NorwayBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    NorwayBankAccount.new({
      user: users(:named_seller),
      account_number: "NO9386011117947",
      account_number_last_four: "7947",
      account_holder_full_name: "Norwegian Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns NO" do
    assert_equal "NO", build.bank_account_type
  end

  test "#country returns NO" do
    assert_equal "NO", build.country
  end

  test "#currency returns nok" do
    assert_equal "nok", build.currency
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******7947", build(account_number_last_four: "7947").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "NO9386011117947").valid?

      no = build(account_number: "NO938601111")
      assert_not no.valid?
      assert_equal "The account number is invalid.", no.errors.full_messages.to_sentence

      no = build(account_number: "NOABCDEFGHIJKLM")
      assert_not no.valid?
      assert_equal "The account number is invalid.", no.errors.full_messages.to_sentence

      no = build(account_number: "NO9386011117947123")
      assert_not no.valid?
      assert_equal "The account number is invalid.", no.errors.full_messages.to_sentence

      no = build(account_number: "129386011117947")
      assert_not no.valid?
      assert_equal "The account number is invalid.", no.errors.full_messages.to_sentence
    end
  end
end
