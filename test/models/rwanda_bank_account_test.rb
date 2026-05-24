require "test_helper"

class RwandaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    RwandaBankAccount.new({
      user: users(:named_seller),
      account_number: "000123456789",
      account_number_last_four: "6789",
      bank_code: "AAAARWRWXXX",
      account_holder_full_name: "Rwandan Creator",
    }.merge(attrs))
  end

  test "#bank_account_type returns RW" do
    assert_equal "RW", build.bank_account_type
  end

  test "#country returns RW" do
    assert_equal "RW", build.country
  end

  test "#currency returns rwf" do
    assert_equal "rwf", build.currency
  end

  test "#routing_number returns valid for 8 to 11 characters" do
    assert build(bank_code: "AAAARWRWXXX").valid?
    assert build(bank_code: "AAAARWRW").valid?
    assert_not build(bank_code: "AAAARWRWXXXX").valid?
    assert_not build(bank_code: "AAAARWR").valid?
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "******6789", build(account_number_last_four: "6789").account_number_visual
  end

  test "#validate_account_number allows records that match the required account number regex" do
    Rails.env.stub(:production?, true) do
      assert build.valid?
      assert build(account_number: "1").valid?
      assert build(account_number: "12345").valid?
      assert build(account_number: "0001234567").valid?
      assert build(account_number: "123456789012345").valid?
    end
  end

  test "#validate_account_number rejects records that do not match the required account number regex" do
    Rails.env.stub(:production?, true) do
      rw = build(account_number: "ABCDEF")
      assert_not rw.valid?
      assert_equal "The account number is invalid.", rw.errors.full_messages.to_sentence

      rw = build(account_number: "1234567890123456")
      assert_not rw.valid?
      assert_equal "The account number is invalid.", rw.errors.full_messages.to_sentence

      rw = build(account_number: "ABC000123456789")
      assert_not rw.valid?
      assert_equal "The account number is invalid.", rw.errors.full_messages.to_sentence
    end
  end
end
