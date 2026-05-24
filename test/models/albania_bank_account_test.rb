require "test_helper"

class AlbaniaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    AlbaniaBankAccount.new({
      user: users(:named_seller),
      account_number: "AL35202111090000000001234567",
      account_number_last_four: "4567",
      bank_code: "AAAAALTXXXX",
      account_holder_full_name: "Albanian Creator I",
    }.merge(attrs))
  end

  test "#bank_account_type returns AL" do
    assert_equal "AL", build.bank_account_type
  end

  test "#country returns AL" do
    assert_equal "AL", build.country
  end

  test "#currency returns all" do
    assert_equal "all", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAAALTXXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "AL******4567", build(account_number_last_four: "4567").account_number_visual
  end
end
