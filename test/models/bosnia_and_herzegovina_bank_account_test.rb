require "test_helper"

class BosniaAndHerzegovinaBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    BosniaAndHerzegovinaBankAccount.new({
      user: users(:named_seller),
      account_number: "BA095520001234567812",
      account_number_last_four: "7812",
      bank_code: "AAAABABAXXX",
      account_holder_full_name: "Bosnia and Herzegovina Creator I",
    }.merge(attrs))
  end

  test "#bank_account_type returns BA" do
    assert_equal "BA", build.bank_account_type
  end

  test "#country returns BA" do
    assert_equal "BA", build.country
  end

  test "#currency returns bam" do
    assert_equal "bam", build.currency
  end

  test "#routing_number returns valid for 11 characters" do
    ba = build
    assert ba.valid?, ba.errors.full_messages.to_sentence
    assert_equal "AAAABABAXXX", ba.routing_number
  end

  test "#account_number_visual returns the visual account number" do
    assert_equal "BA******6000", build(account_number_last_four: "6000").account_number_visual
  end
end
