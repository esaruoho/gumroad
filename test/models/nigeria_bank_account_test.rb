require "test_helper"

class NigeriaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    NigeriaBankAccount.new({
      user: users(:named_seller),
      account_number: "1111111112",
      account_number_last_four: "1112",
      bank_code: "AAAANGLAXXX",
      account_holder_full_name: "Nigerian Creator I",
    }.merge(attrs))
  end

  test "#bank_account_type returns NG" do
    assert_equal "NG", build.bank_account_type
  end

  test "#country returns NG" do
    assert_equal "NG", build.country
  end

  test "#currency returns ngn" do
    assert_equal "ngn", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAANGLAXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "NG******1112", build(account_number_last_four: "1112").account_number_visual
  end
end
