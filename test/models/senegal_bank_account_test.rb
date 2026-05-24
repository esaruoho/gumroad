require "test_helper"

class SenegalBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    SenegalBankAccount.new({
      user: users(:named_seller),
      account_number: "SN08SN0100152000048500003035",
      account_number_last_four: "3035",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns SN" do
    assert_equal "SN", build.bank_account_type
  end

  test "#country returns SN" do
    assert_equal "SN", build.country
  end

  test "#currency returns xof" do
    assert_equal "xof", build.currency
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******3035", build(account_number_last_four: "3035").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    assert build.valid?
    assert build(account_number: "SN08SN0100152000048500003035").valid?
    assert build(account_number: "SN62370400440532013001").valid?

    sn = build(account_number: "012345678")
    assert_not sn.valid?
    assert_equal "The account number is invalid.", sn.errors.full_messages.to_sentence

    sn = build(account_number: "ABCDEFGHIJKLMNOPQRSTUV")
    assert_not sn.valid?
    assert_equal "The account number is invalid.", sn.errors.full_messages.to_sentence

    sn = build(account_number: "SN08SN01001520000485000030355")
    assert_not sn.valid?
    assert_equal "The account number is invalid.", sn.errors.full_messages.to_sentence

    sn = build(account_number: "SN08SN010015200004850")
    assert_not sn.valid?
    assert_equal "The account number is invalid.", sn.errors.full_messages.to_sentence
  end
end
