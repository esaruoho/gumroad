require "test_helper"

class PeruBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    PeruBankAccount.new({
      user: users(:named_seller),
      account_number: "99934500012345670024",
      account_number_last_four: "0024",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns PE" do
    assert_equal "PE", build.bank_account_type
  end

  test "#country returns PE" do
    assert_equal "PE", build.country
  end

  test "#currency returns pen" do
    assert_equal "pen", build.currency
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******2874", build(account_number_last_four: "2874").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "01234567898765432101").valid?

      pe = build(account_number: "012345678")
      assert_not pe.valid?
      assert_equal "The account number is invalid.", pe.errors.full_messages.to_sentence

      pe = build(account_number: "ABCDEFGHIJKLMNOPQRSTUV")
      assert_not pe.valid?
      assert_equal "The account number is invalid.", pe.errors.full_messages.to_sentence

      pe = build(account_number: "01234567898765432123456")
      assert_not pe.valid?
      assert_equal "The account number is invalid.", pe.errors.full_messages.to_sentence

      pe = build(account_number: "012345678987654321234")
      assert_not pe.valid?
      assert_equal "The account number is invalid.", pe.errors.full_messages.to_sentence
    end
  end
end
