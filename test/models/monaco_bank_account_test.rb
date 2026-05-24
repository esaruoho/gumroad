require "test_helper"

class MonacoBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    MonacoBankAccount.new({
      user: users(:named_seller),
      account_number: "MC5810096180790123456789085",
      account_number_last_four: "9085",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "#bank_account_type returns MC" do
    assert_equal "MC", build.bank_account_type
  end

  test "#country returns MC" do
    assert_equal "MC", build.country
  end

  test "#currency returns eur" do
    assert_equal "eur", build.currency
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "MC******6789", build(account_number_last_four: "6789").account_number_visual
  end
end
