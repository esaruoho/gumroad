require "test_helper"

class ArgentinaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    ArgentinaBankAccount.new({
      user: users(:named_seller),
      account_number: "0110000600000000000000",
      account_number_last_four: "0000",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns argentina" do
    assert_equal "AR", build.bank_account_type
  end

  test "#country returns AR" do
    assert_equal "AR", build.country
  end

  test "#currency returns ars" do
    assert_equal "ars", build.currency
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end

  test "#account_number_visual returns the visual account number with country code prefixed" do
    assert_equal "******2874", build(account_number_last_four: "2874").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "0123456789876543212345").valid?

      ba = build(account_number: "012345678")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "ABCDEFGHIJKLMNOPQRSTUV")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "01234567898765432123456")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "012345678987654321234")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
