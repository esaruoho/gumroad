require "test_helper"

class MauritiusBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    MauritiusBankAccount.new({
      user: users(:named_seller),
      account_number: "MU17BOMM0101101030300200000MUR",
      account_number_last_four: "0MUR",
      bank_code: "AAAAMUMUXYZ",
      account_holder_full_name: "John Doe",
    }.merge(attrs))
  end

  test "#bank_account_type returns MU" do
    assert_equal "MU", build.bank_account_type
  end

  test "#country returns MU" do
    assert_equal "MU", build.country
  end

  test "#currency returns mur" do
    assert_equal "mur", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAAMUMUXYZ", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "MU******9123", build(account_number_last_four: "9123").account_number_visual
  end
end
