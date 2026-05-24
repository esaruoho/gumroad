require "test_helper"

class MexicoBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    MexicoBankAccount.new({
      user: users(:named_seller),
      account_number: "000000001234567897",
      account_number_last_four: "7897",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns mexico" do
    assert_equal "MX", build.bank_account_type
  end

  test "#country returns MX" do
    assert_equal "MX", build.country
  end

  test "#currency returns mxn" do
    assert_equal "mxn", build.currency
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******7897", build(account_number_last_four: "7897").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "000000001234567897").valid?

      ba = build(account_number: "MX12345")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "DE61109010140000071219812874")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "8937040044053201300000")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "MXABCDE")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
