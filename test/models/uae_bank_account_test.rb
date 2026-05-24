require "test_helper"

class UaeBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    UaeBankAccount.new({
      user: users(:named_seller),
      account_number: "AE070331234567890123456",
      account_number_last_four: "3456",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns AE" do
    assert_equal "AE", build.bank_account_type
  end

  test "#country returns AE" do
    assert_equal "AE", build.country
  end

  test "#currency returns aed" do
    assert_equal "aed", build.currency
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end

  test "#account_number_visual returns the visual account number with country code prefixed" do
    assert_equal "AE******3456", build(account_number_last_four: "3456").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "AE 0703 3123 4567 8901 2345 6").valid?

      ba = build(account_number: "AE12345")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "DE61109010140000071219812874")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "8937040044053201300000")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "AEABCDE")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
