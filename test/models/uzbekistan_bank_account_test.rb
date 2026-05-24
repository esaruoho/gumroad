require "test_helper"

class UzbekistanBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    UzbekistanBankAccount.new({
      user: users(:named_seller),
      account_number: "99934500012345670024",
      bank_code: "AAAAUZUZXXX",
      branch_code: "00000",
      account_number_last_four: "0024",
      account_holder_full_name: "Chuck Bartowski",
    }.merge(attrs))
  end

  test "#bank_account_type returns UZ" do
    assert_equal "UZ", build.bank_account_type
  end

  test "#country returns UZ" do
    assert_equal "UZ", build.country
  end

  test "#currency returns uzs" do
    assert_equal "uzs", build.currency
  end

  test "#routing_number returns valid bank code and branch code" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAAUZUZXXX-00000", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******0024", build(account_number_last_four: "0024").account_number_visual
  end

  test "#validate_bank_code allows valid bank code format" do
    assert build(bank_code: "AAAAUZUZXXX").valid?
    assert build(bank_code: "BBBBUZUZYYY").valid?
    refute build(bank_code: "AAAAUZU").valid?
    refute build(bank_code: "AAAAUZUZXXXX").valid?
  end

  test "#validate_account_number allows valid account number format" do
    assert build(account_number: "99934500012345670024").valid?
    assert build(account_number: "12345").valid?
    assert build(account_number: "12345678901234567890").valid?
    refute build(account_number: "1234").valid?
    refute build(account_number: "123456789012345678901").valid?
  end
end
