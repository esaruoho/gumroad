# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. AchAccount spec (292 LOC, 11 create()/build()
# refs) is mostly pure routing/account number regex assertions, which would
# be portable — but every `build(:ach_account)` case threads through a User
# factory + Strongbox-encrypted account_number column whose setter routes
# through `BankAccount#account_number=` (decrypts via STRONGBOX_GENERAL_PASSWORD).
# The fixture-only path needs a new ach_accounts.yml + bank_accounts ach
# rows; the validation tests further need a Bank fixture for the bank_name
# enforcement (GREEN DOT BANK / METABANK MEMPHIS branches). Multiple top-level
# `expect(described_class).to receive(:routing_number_valid?)` partial doubles
# also have no Minitest equivalent without a recorder shim. Defer.
#
# Original spec: spec/models/ach_account_spec.rb
class AchAccountTest < ActiveSupport::TestCase
  test "TODO: migrate — Strongbox account_number + Bank fixture + partial doubles" do
    skip "11 build(:ach_account) refs through User + Strongbox-encrypted account_number; Bank fixture needed for GREEN DOT BANK / METABANK MEMPHIS branches; RSpec partial doubles on described_class. Out of scope for mechanical model backfill."
  end
end
