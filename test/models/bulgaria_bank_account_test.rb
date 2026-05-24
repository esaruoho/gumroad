require "test_helper"

class BulgariaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    BulgariaBankAccount.new({
      user: users(:named_seller),
      account_number: "BG80BNBG96611020345678",
      account_number_last_four: "2874",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns bulgaria" do
    assert_equal "BG", build.bank_account_type
  end

  test "#country returns BG" do
    assert_equal "BG", build.country
  end

  test "#currency returns eur" do
    assert_equal "eur", build.currency
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end

  test "#account_number_visual returns the visual account number with country code prefixed" do
    assert_equal "BG******2874", build(account_number_last_four: "2874").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "BG80 BNBG 9661 1020 3456 78").valid?

      ba = build(account_number: "BG12345")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "DE61109010140000071219812874")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "8937040044053201300000")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "BGABCDE")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
