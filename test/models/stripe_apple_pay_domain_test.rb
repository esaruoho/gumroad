# frozen_string_literal: true

require "test_helper"

class StripeApplePayDomainTest < ActiveSupport::TestCase
  test "validates presence of attributes" do
    record = StripeApplePayDomain.create
    assert_equal(
      { user: ["can't be blank"], domain: ["can't be blank"], stripe_id: ["can't be blank"] },
      record.errors.messages
    )
  end
end
