require "test_helper"

class SerbiaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    SerbiaBankAccount.new({
      user: users(:named_seller),
      account_number: "RS35105008123123123173",
      account_number_last_four: "3173",
      bank_code: "TESTSERBXXX",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns RS" do
    assert_equal "RS", build.bank_account_type
  end

  test "#country returns RS" do
    assert_equal "RS", build.country
  end

  test "#currency returns rsd" do
    assert_equal "rsd", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "TESTSERBXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "RS******9123", build(account_number_last_four: "9123").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "RS35105008123123123173").valid?

      rs = build(account_number: "MA12345")
      assert_not rs.valid?
      assert_equal "The account number is invalid.", rs.errors.full_messages.to_sentence

      rs = build(account_number: "DE61109010140000071219812874")
      assert_not rs.valid?
      assert_equal "The account number is invalid.", rs.errors.full_messages.to_sentence

      rs = build(account_number: "89370400044053201300000")
      assert_not rs.valid?
      assert_equal "The account number is invalid.", rs.errors.full_messages.to_sentence

      rs = build(account_number: "CRABCDE")
      assert_not rs.valid?
      assert_equal "The account number is invalid.", rs.errors.full_messages.to_sentence
    end
  end
end
