require "test_helper"

class MoldovaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    MoldovaBankAccount.new({
      user: users(:named_seller),
      account_number: "MD07AG123456789012345678",
      account_number_last_four: "5678",
      bank_code: "AAAAMDMDXXX",
      account_holder_full_name: "Moldova Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns MD" do
    assert_equal "MD", build.bank_account_type
  end

  test "#country returns MD" do
    assert_equal "MD", build.country
  end

  test "#currency returns mdl" do
    assert_equal "mdl", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAAMDMDXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******5678", build(account_number_last_four: "5678").account_number_visual
  end

  test "#validate_bank_code allows 8 or 11 character SWIFT/BIC codes with MD country code" do
    assert build(bank_code: "AAAAMDMDXXX").valid?
    assert build(bank_code: "BBBBMDMDYYY").valid?
    assert build(bank_code: "AGRNMD2XZZZ").valid?
    assert build(bank_code: "AGROMDMD").valid?
    assert build(bank_code: "AGRLMDMM").valid?
    assert_not build(bank_code: "AGRNMD2ZZ").valid?
    assert_not build(bank_code: "AGRNMD2ZZX").valid?
    assert_not build(bank_code: "AGRNMM2XZZZ").valid?
    assert_not build(bank_code: "AGRNMD2XZZZZ").valid?
    assert_not build(bank_code: "AAAMDMDXXX").valid?
    assert_not build(bank_code: "AAAAMDMDXXXX").valid?
  end

  test "#validate_account_number allows only 24 characters in the correct format" do
    assert build(account_number: "MD07AG123456789012345678").valid?
    assert build(account_number: "MD11BC987654321098765432").valid?
    assert_not build(account_number: "MD07AG12345678901234567").valid?
    assert_not build(account_number: "MD07AG1234567890123456789").valid?
  end
end
