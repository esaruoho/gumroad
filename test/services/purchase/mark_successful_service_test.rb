# frozen_string_literal: true

require "test_helper"

class Purchase::MarkSuccessfulServiceTest < ActiveSupport::TestCase
  setup do
    skip "TODO: migrate spec/services/purchase/mark_successful_service_spec.rb " \
         "(exercises purchase.update_balance_and_mark_successful! → balance / merchant " \
         "account / Stripe path + seller.save_gumroad_day_timezone; needs balances + " \
         "merchant_accounts fixtures and a fully-wired in_progress purchase — Tier-4)."
  end
end
