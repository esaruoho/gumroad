require "test_helper"

class MalaysiaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    MalaysiaBankAccount.new({
      user: users(:named_seller),
      account_number: "000123456000",
      account_number_last_four: "6000",
      bank_code: "HBMBMYKL",
      account_holder_full_name: "Malaysian Creator I",
    }.merge(attrs))
  end

  test "#bank_account_type returns MY" do
    assert_equal "MY", build.bank_account_type
  end

  test "#country returns MY" do
    assert_equal "MY", build.country
  end

  test "#currency returns myr" do
    assert_equal "myr", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "HBMBMYKL", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6000", build(account_number_last_four: "6000").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "00012345678910111").valid?
      assert build(account_number: "00012").valid?

      ba = build(account_number: "MA123")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "MY123456789101112")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "000123456789101112")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "CRABC")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
