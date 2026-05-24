require "test_helper"

class CoteDIvoireBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    CoteDIvoireBankAccount.new({
      user: users(:named_seller),
      account_number: "CI93CI0080111301134291200589",
      account_number_last_four: "0589",
      account_holder_full_name: "Cote d'Ivoire Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns CI" do
    assert_equal "CI", build.bank_account_type
  end

  test "#country returns CI" do
    assert_equal "CI", build.country
  end

  test "#currency returns xof" do
    assert_equal "xof", build.currency
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "CI******0589", build(account_number_last_four: "0589").account_number_visual
  end

  test "#routing_number returns nil" do
    assert_nil build.routing_number
  end
end
