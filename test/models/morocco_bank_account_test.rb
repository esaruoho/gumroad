require "test_helper"

class MoroccoBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    MoroccoBankAccount.new({
      user: users(:named_seller),
      account_number: "MA64011519000001205000534921",
      account_number_last_four: "4921",
      bank_code: "AAAAMAMAXXX",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns Morocco" do
    assert_equal "MA", build.bank_account_type
  end

  test "#country returns MA" do
    assert_equal "MA", build.country
  end

  test "#currency returns mad" do
    assert_equal "mad", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAAMAMAXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "MA******9123", build(account_number_last_four: "9123").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "MA64011519000001205000534921").valid?
      assert build(account_number: "MA62370400440532013001").valid?

      ba = build(account_number: "MA12345")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "DE61109010140000071219812874")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "8937040044053201300000")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

      ba = build(account_number: "CRABCDE")
      assert_not ba.valid?
      assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
    end
  end
end
