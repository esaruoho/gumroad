require "test_helper"

class RomaniaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    RomaniaBankAccount.new({
      user: users(:named_seller),
      account_number: "RO49AAAA1B31007593840000",
      account_number_last_four: "0000",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns RO" do
    assert_equal "RO", build.bank_account_type
  end

  test "#country returns RO" do
    assert_equal "RO", build.country
  end

  test "#currency returns ron" do
    assert_equal "ron", build.currency
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "RO******0000", build(account_number_last_four: "0000").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "RO49 AAAA 1B31 0075 9384 0000").valid?

      ro = build(account_number: "RO12345")
      assert_not ro.valid?
      assert_equal "The account number is invalid.", ro.errors.full_messages.to_sentence

      ro = build(account_number: "DE61109010140000071219812874")
      assert_not ro.valid?
      assert_equal "The account number is invalid.", ro.errors.full_messages.to_sentence

      ro = build(account_number: "8937040044053201300000")
      assert_not ro.valid?
      assert_equal "The account number is invalid.", ro.errors.full_messages.to_sentence

      ro = build(account_number: "ROABCDE")
      assert_not ro.valid?
      assert_equal "The account number is invalid.", ro.errors.full_messages.to_sentence
    end
  end
end
