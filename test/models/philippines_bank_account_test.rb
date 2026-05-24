require "test_helper"

class PhilippinesBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    PhilippinesBankAccount.new({
      user: users(:named_seller),
      account_number: "01567890123456789",
      bank_number: "BCDEFGHI123",
      account_number_last_four: "I123",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns PH" do
    assert_equal "PH", build.bank_account_type
  end

  test "#country returns PH" do
    assert_equal "PH", build.country
  end

  test "#currency returns php" do
    assert_equal "php", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "BCDEFGHI123", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_bank_code allows 8 to 11 characters only" do
    assert build(bank_code: "BCDEFGHI").valid?
    assert build(bank_code: "BCDEFGHI1").valid?
    assert build(bank_code: "BCDEFGHI12").valid?
    assert build(bank_code: "BCDEFGHI123").valid?
    assert_not build(bank_code: "BCDEFGH").valid?
    assert_not build(bank_code: "BCDEFGHI1234").valid?
  end

  test "#validate_account_number allows records that match the required account number regex" do
    assert build(account_number: "1").valid?
    assert build(account_number: "123456789").valid?
    assert build(account_number: "12345678901234567").valid?

    ph = build(account_number: "ABCDEFGHIJKL")
    assert_not ph.valid?
    assert_equal "The account number is invalid.", ph.errors.full_messages.to_sentence

    ph = build(account_number: "123456789012345678")
    assert_not ph.valid?
    assert_equal "The account number is invalid.", ph.errors.full_messages.to_sentence
  end
end
