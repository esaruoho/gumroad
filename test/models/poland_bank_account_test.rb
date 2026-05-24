require "test_helper"

class PolandBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    PolandBankAccount.new({
      user: users(:named_seller),
      account_number: "PL61109010140000071219812874",
      account_number_last_four: "2874",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns PL" do
    assert_equal "PL", build.bank_account_type
  end

  test "#country returns PL" do
    assert_equal "PL", build.country
  end

  test "#currency returns pln" do
    assert_equal "pln", build.currency
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "PL******2874", build(account_number_last_four: "2874").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "PL61 1090 1014 0000 0712 1981 2874").valid?

      pl = build(account_number: "PL12345")
      assert_not pl.valid?
      assert_equal "The account number is invalid.", pl.errors.full_messages.to_sentence

      pl = build(account_number: "DE61109010140000071219812874")
      assert_not pl.valid?
      assert_equal "The account number is invalid.", pl.errors.full_messages.to_sentence

      pl = build(account_number: "8937040044053201300000")
      assert_not pl.valid?
      assert_equal "The account number is invalid.", pl.errors.full_messages.to_sentence

      pl = build(account_number: "PLABCDE")
      assert_not pl.valid?
      assert_equal "The account number is invalid.", pl.errors.full_messages.to_sentence
    end
  end
end
