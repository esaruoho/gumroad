require "test_helper"

class SriLankaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    SriLankaBankAccount.new({
      user: users(:named_seller),
      bank_code: "AAAALKLXXXX",
      branch_code: "7010999",
      account_number: "0000012345",
      account_number_last_four: "2345",
      account_holder_full_name: "Sri Lankan Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns LK" do
    assert_equal "LK", build.bank_account_type
  end

  test "#country returns LK" do
    assert_equal "LK", build.country
  end

  test "#currency returns lkr" do
    assert_equal "lkr", build.currency
  end

  test "#routing_number returns valid for 8 to 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAALKLXXXX-7010999", ba.routing_number
  end

  test "#branch_code returns the branch code" do
    assert_equal "7010999", build(branch_code: "7010999").branch_code
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******2345", build(account_number_last_four: "2345").account_number_visual
  end

  test "#validate_branch_code allows exactly 7 digits" do
    assert build(branch_code: "7010999").valid?
    refute build(branch_code: "701099").valid?
    refute build(branch_code: "70109990").valid?
  end

  test "#validate_bank_code allows 11 characters only" do
    assert build(bank_code: "AAAALKLXXXX").valid?
    refute build(bank_code: "AAAALKLXXXXX").valid?
    refute build(bank_code: "AAAALKLXXX").valid?
  end

  test "#validate_account_number allows 10 to 18 digits only" do
    assert build(account_number: "0000012345").valid?
    assert build(account_number: "000001234567890123").valid?
    refute build(account_number: "000001234").valid?
    refute build(account_number: "0000012345678901234").valid?
  end
end
