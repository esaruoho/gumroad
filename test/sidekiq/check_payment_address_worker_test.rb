# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skipped during bulk fixtures-only migration.
# Reason: 40 FactoryBot refs (skill threshold) — fraud detection chain across users/ach_accounts/platform_blocks. Skip-batch.
# Original spec: spec/sidekiq/check_payment_address_worker_spec.rb
class CheckPaymentAddressWorkerTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/check_payment_address_worker_spec.rb — 40 FactoryBot refs (skill threshold) — fraud detection chain across users/ach_accounts/platform_blocks. Skip-batch."
  end
end
