require "test_helper"

class NigerBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    NigerBankAccount.new({
      user: users(:named_seller),
      account_number: "NE58NE0380100100130305000268",
      account_number_last_four: "0268",
      account_holder_full_name: "Niger Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns NE" do
    assert_equal "NE", build.bank_account_type
  end

  test "#country returns NE" do
    assert_equal "NE", build.country
  end

  test "#currency returns xof" do
    assert_equal "xof", build.currency
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "NE******0268", build(account_number_last_four: "0268").account_number_visual
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end
end
