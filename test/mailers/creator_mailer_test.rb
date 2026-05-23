# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. This spec was skip-batched during the bulk
# fixtures-only migration. The remaining cases need:
#   - #gumroad_day_fee_saved: user + product + purchase fixtures w/ timezone-bound
#     created_at and price_cents to drive User#gumroad_day_saved_fee_amount.
#   - #year_in_review: spec uses an in-memory analytics_data hash and calls
#     ProductPresenter.card_for_email — convertible but needs currency_type
#     stubbing + asset/host wiring.
#   - #bundles_marketing: pure-hash bundles + URL helper assertions; convertible
#     but needs ActionMailer::TestCase + URL helper boilerplate.
#   - #scheduled_payout_chargeback_hold: scheduled_payouts fixture with
#     action: "payout" (existing fixtures use "pause"); needs new row.
# Two cases also assert via Capybara's `have_text`/`have_link` matchers, which
# require translating to assert_includes / Nokogiri queries.
#
# Original spec: spec/mailers/creator_mailer_spec.rb (7 FactoryBot refs)
class CreatorMailerTest < ActionMailer::TestCase
  test "TODO: migrate from RSpec — needs scheduled_payouts(action:payout) + URL helpers + capybara matcher translation" do
    skip "TODO: migrate spec/mailers/creator_mailer_spec.rb (multi-method mailer; needs new scheduled_payouts row + Capybara→assert_includes rewrite)"
  end
end
