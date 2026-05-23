# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only
# migration. Requires:
#   - merchant_accounts.yml fixtures (new file): including a Stripe-flavored
#     row, a PayPal-flavored row, and a country=nil row; with linkage to a
#     User fixture.
#   - Stripe::Account.retrieve / Stripe::PermissionError stubbing via the
#     ConstantStubbingHelpers or method-level Minitest stubs (the existing
#     stripe-mock at :12111 does not return PermissionError shapes).
#   - MerchantAccount#paypal_account_details stubbing for the PayPal branch.
# Estimated 2 new YAML files + a Stripe stub helper.
#
# Original spec: spec/presenters/admin/merchant_account_presenter_spec.rb (9 FactoryBot refs)
class Admin::MerchantAccountPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — needs merchant_accounts.yml + Stripe::Account stubbing" do
    skip "TODO: migrate spec/presenters/admin/merchant_account_presenter_spec.rb (needs merchant_accounts.yml + Stripe/PayPal stubs)"
  end
end
