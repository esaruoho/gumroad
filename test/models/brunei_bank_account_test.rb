require "test_helper"

class BruneiBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    BruneiBankAccount.new({
      user: users(:named_seller),
      account_number: "0000123456789",
      account_number_last_four: "6789",
      bank_code: "AAAABNBBXXX",
      account_holder_full_name: "Brunei Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns BN" do
    assert_equal "BN", build.bank_account_type
  end

  test "#country returns BN" do
    assert_equal "BN", build.country
  end

  test "#currency returns bnd" do
    assert_equal "bnd", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAABNBBXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    assert build.valid?
    assert build(account_number: "000012345").valid?
    assert build(account_number: "1").valid?
    assert build(account_number: "000012345678").valid?

    ba = build(account_number: "000012345678910")
    assert_not ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence

    ba = build(account_number: "BN0012345678910")
    assert_not ba.valid?
    assert_equal "The account number is invalid.", ba.errors.full_messages.to_sentence
  end
end
