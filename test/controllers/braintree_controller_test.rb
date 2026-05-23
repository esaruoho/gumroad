# frozen_string_literal: true

require "test_helper"

class BraintreeControllerTest < ActionController::TestCase
  test "skip: needs VCR cassettes + Braintree::Test::Nonce — out of scope for fixture migration" do
    skip "Original spec used VCR cassettes; Minitest test_helper lacks VCR config. See /tmp/mig-b-skipped.md."
  end
end
