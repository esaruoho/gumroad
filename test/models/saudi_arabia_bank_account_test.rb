require "test_helper"

class SaudiArabiaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    SaudiArabiaBankAccount.new({
      user: users(:named_seller),
      account_number: "SA4420000001234567891234",
      account_number_last_four: "1234",
      bank_code: "RIBLSARIXXX",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns SA" do
    assert_equal "SA", build.bank_account_type
  end

  test "#country returns SA" do
    assert_equal "SA", build.country
  end

  test "#currency returns sar" do
    assert_equal "sar", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "RIBLSARIXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******7519", build(account_number_last_four: "7519").account_number_visual
  end

  test "#validate_bank_code allows 8 to 11 characters only" do
    assert build(bank_code: "RIBLSARIXXX").valid?
    assert build(bank_code: "RIBLSARI").valid?
    assert_not build(bank_code: "RIBLSAR").valid?
    assert_not build(bank_code: "RIBLSARIXXXX").valid?
  end
end
