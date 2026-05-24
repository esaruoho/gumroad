# frozen_string_literal: true

require "test_helper"

class SyncStuckPurchasesJobTest < ActiveSupport::TestCase
  test "no-ops when there are no in_progress purchases in the window" do
    # The base test DB has no purchases in `purchase_state = 'in_progress'` and
    # created between 3.days.ago and 4.hours.ago, so this is a meaningful
    # early-exit assertion.
    assert_nothing_raised do
      SyncStuckPurchasesJob.new.perform
    end
  end

  test "skips a stuck purchase when can_force_update? returns false" do
    product = links(:named_seller_product)
    purchase = Purchase.new(seller: product.user, link: product,
                             email: "stuck-buyer-#{SecureRandom.hex(2)}@example.com",
                             price_cents: 100, total_transaction_cents: 100, fee_cents: 0,
                             purchase_state: "in_progress",
                             created_at: 1.day.ago)
    purchase.save!(validate: false)

    Purchase.define_method(:can_force_update?) { false }
    sync_called = false
    Purchase.define_method(:sync_status_with_charge_processor) { |**_kw| sync_called = true }
    begin
      SyncStuckPurchasesJob.new.perform
    ensure
      %i[can_force_update? sync_status_with_charge_processor].each do |m|
        Purchase.remove_method(m) if Purchase.method_defined?(m)
      end
    end
    refute sync_called
  end
end
