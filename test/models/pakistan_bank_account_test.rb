require "test_helper"

class PakistanBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    PakistanBankAccount.new({
      user: users(:named_seller),
      account_number: "PK36SCBL0000001123456702",
      account_number_last_four: "6702",
      bank_code: "AAAAPKKAXXX",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns PK" do
    assert_equal "PK", build.bank_account_type
  end

  test "#country returns PK" do
    assert_equal "PK", build.country
  end

  test "#currency returns pkr" do
    assert_equal "pkr", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAAPKKAXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6702", build(account_number_last_four: "6702").account_number_visual
  end

  test "#validate_bank_code allows 8 to 11 characters only" do
    assert build(bank_code: "AAAAPKKAXXX").valid?
    assert build(bank_code: "AAAAPKKA").valid?
    assert_not build(bank_code: "AAAAPKK").valid?
    assert_not build(bank_code: "AAAAPKKAXXXX").valid?
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "PK36SCBL0000001123456702").valid?

      pk = build(account_number: "PK12345")
      assert_not pk.valid?
      assert_equal "The account number is invalid.", pk.errors.full_messages.to_sentence

      pk = build(account_number: "PK36SCBL00000011234567021")
      assert_not pk.valid?
      assert_equal "The account number is invalid.", pk.errors.full_messages.to_sentence

      pk = build(account_number: "PK36SCBL000000112345670")
      assert_not pk.valid?
      assert_equal "The account number is invalid.", pk.errors.full_messages.to_sentence

      pk = build(account_number: "PKABCDE")
      assert_not pk.valid?
      assert_equal "The account number is invalid.", pk.errors.full_messages.to_sentence
    end
  end
end
