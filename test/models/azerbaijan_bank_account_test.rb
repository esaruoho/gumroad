require "test_helper"

class AzerbaijanBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    AzerbaijanBankAccount.new({
      user: users(:named_seller),
      account_number: "AZ77ADJE12345678901234567890",
      account_number_last_four: "7890",
      bank_code: "123456",
      branch_code: "123456",
      account_holder_full_name: "Azerbaijani Creator I",
    }.merge(attrs))
  end

  test "#bank_account_type returns AZ" do
    assert_equal "AZ", build.bank_account_type
  end

  test "#country returns AZ" do
    assert_equal "AZ", build.country
  end

  test "#currency returns azn" do
    assert_equal "azn", build.currency
  end

  test "#routing_number returns valid for 6 digits with hyphen after 3" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "123456-123456", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "AZ******7890", build(account_number_last_four: "7890").account_number_visual
  end

  test "#validate_bank_code allows 6 digits only" do
    assert build(bank_code: "123456").valid?
    assert_not build(bank_code: "12345").valid?
    assert_not build(bank_code: "1234567").valid?
    assert_not build(bank_code: "ABCDEF").valid?
  end

  test "#validate_branch_code allows 6 digits only" do
    assert build(branch_code: "123456").valid?
    assert_not build(branch_code: "12345").valid?
    assert_not build(branch_code: "1234567").valid?
    assert_not build(branch_code: "ABCDEF").valid?
  end
end
