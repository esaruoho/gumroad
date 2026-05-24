require "test_helper"

class TunisiaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    TunisiaBankAccount.new({
      user: users(:named_seller),
      account_number: "TN5904018104004942712345",
      account_number_last_four: "2345",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns TN" do
    assert_equal "TN", build.bank_account_type
  end

  test "#country returns TN" do
    assert_equal "TN", build.country
  end

  test "#currency returns tnd" do
    assert_equal "tnd", build.currency
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "TN******2345", build(account_number_last_four: "2345").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "TN 5904 0181 0400 4942 7123 45").valid?

      ba = build(account_number: "TN12345")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "DE61109010140000071219812874")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "8937040044053201300000")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "TNABCDE")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
