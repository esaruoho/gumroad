# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only
# migration. Requires:
#   - merchant_accounts.yml (referenced by purchase.merchant_account)
#   - prices.yml row matching the product (per skill pitfall: any product
#     touched by price_formatted-style presenters needs an explicit price row)
#   - Card/charge processor stubbing (purchase.card_type / card_country /
#     stripe_fingerprint / stripe_transaction_id are populated by the
#     create-time pipeline; fixture rows need values spelled out)
#   - Variants list / product_purchases / refunds / offer_code / url_redirect
#     scaffolding (lots of nil-default cases).
# Estimated 3+ new fixture tables. Combined with the broad #props match,
# higher-yield to revisit after merchant_accounts + payments fixtures land.
#
# Original spec: spec/presenters/admin/purchase_presenter_spec.rb (14 FactoryBot refs)
class Admin::PurchasePresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — needs merchant_accounts.yml + prices.yml + card/transaction columns" do
    skip "TODO: migrate spec/presenters/admin/purchase_presenter_spec.rb (14 FB refs; needs merchant_accounts.yml + populated purchase card/stripe columns)"
  end
end
