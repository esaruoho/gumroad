require "test_helper"

class AlgeriaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    AlgeriaBankAccount.new({
      user: users(:named_seller),
      account_number: "00001234567890123456",
      account_number_last_four: "3456",
      bank_code: "AAAADZDZXXX",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns DZ" do
    assert_equal "DZ", build.bank_account_type
  end

  test "#country returns DZ" do
    assert_equal "DZ", build.country
  end

  test "#currency returns dzd" do
    assert_equal "dzd", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAADZDZXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******1234", build(account_number_last_four: "1234").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "00001234567890123456").valid?

      assert build(account_number: "00001001001111111116").valid?
      assert build(account_number: "00001001001111111113").valid?
      assert build(account_number: "00001001002222222227").valid?
      assert build(account_number: "00001001003333333335").valid?
      assert build(account_number: "00001001004444444440").valid?

      ba = build(account_number: "12345")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "123456789012345678901")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "ABCD12345678901234XX")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
