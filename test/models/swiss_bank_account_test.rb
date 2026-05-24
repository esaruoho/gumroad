require "test_helper"

class SwissBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    SwissBankAccount.new({
      user: users(:named_seller),
      account_number: "CH9300762011623852957",
      account_number_last_four: "3000",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns CH" do
    assert_equal "CH", build.bank_account_type
  end

  test "#country returns CH" do
    assert_equal "CH", build.country
  end

  test "#currency returns chf" do
    assert_equal "chf", build.currency
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end

  test "#account_number_visual returns the visual account number with country code prefixed" do
    assert_equal "CH******3000", build(account_number_last_four: "3000").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "CH1234567890123456789").valid?

      ba = build(account_number: "CH12345")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "DE9300762011623852957")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "8937040044053201300000")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "CHABCDE")
      refute ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
