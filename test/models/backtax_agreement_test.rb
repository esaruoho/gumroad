# frozen_string_literal: true

require "test_helper"

class BacktaxAgreementTest < ActiveSupport::TestCase
  def attrs
    { user: users(:named_seller), jurisdiction: "AUSTRALIA", signature: "Edgar Gumstein" }
  end

  test "is valid with expected parameters" do
    assert BacktaxAgreement.new(attrs).valid?
  end

  test "validates the presence of a signature" do
    assert_not BacktaxAgreement.new(attrs.merge(signature: nil)).valid?
  end

  test "validates the inclusion of jurisdiction within a certain set" do
    assert_not BacktaxAgreement.new(attrs.merge(jurisdiction: "United States")).valid?
  end
end
