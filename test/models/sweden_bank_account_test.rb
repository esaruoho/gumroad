require "test_helper"

class SwedenBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    SwedenBankAccount.new({
      user: users(:named_seller),
      account_number: "SE3550000000054910000003",
      account_number_last_four: "0003",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns SE" do
    assert_equal "SE", build.bank_account_type
  end

  test "#country returns SE" do
    assert_equal "SE", build.country
  end

  test "#currency returns sek" do
    assert_equal "sek", build.currency
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end

  test "#account_number_visual returns the visual account number with country code prefixed" do
    assert_equal "SE******0003", build(account_number_last_four: "0003").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "SE35 5000 0000 0549 1000 0003").valid?

      ba = build(account_number: "SE12345")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "DE61109010140000071219812874")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "8937040044053201300000")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "SEABCDE")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
