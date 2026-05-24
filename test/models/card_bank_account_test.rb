# frozen_string_literal: true

require "test_helper"

class CardBankAccountTest < ActiveSupport::TestCase
  test "TODO: migrate from spec/models/card_bank_account_spec.rb" do
    skip "Skip-batch: requires VCR cassettes for Stripe card tokenization " \
         "(create(:cc_token_chargeable) hits Stripe to mint a real token + funding_type/card_country). " \
         "Re-migrate with stripe-mock + fixture credit_cards.yml rows carrying funding_type/card_country."
  end
end
