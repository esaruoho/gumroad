require "test_helper"

class BahrainBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    BahrainBankAccount.new({
      user: users(:named_seller),
      account_number: "BH29BMAG1299123456BH00",
      account_number_last_four: "BH00",
      bank_code: "AAAABHBMXYZ",
      account_holder_full_name: "Bahrainian Creator I",
    }.merge(attrs))
  end

  test "#bank_account_type returns BH" do
    assert_equal "BH", build.bank_account_type
  end

  test "#country returns BH" do
    assert_equal "BH", build.country
  end

  test "#currency returns bhd" do
    assert_equal "bhd", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAABHBMXYZ", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "BH******BH00", build(account_number_last_four: "BH00").account_number_visual
  end
end
