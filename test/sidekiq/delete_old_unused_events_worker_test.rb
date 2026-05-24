# frozen_string_literal: true

require "test_helper"

class DeleteOldUnusedEventsWorkerTest < ActiveSupport::TestCase
  test "deletes targeted (non-permitted) events outside the retention window" do
    stub_const(DeleteOldUnusedEventsWorker, :DELETION_BATCH_SIZE, 1) do
      # Non-permitted event older than 2 months — should be deleted.
      Event.create!(event_name: "i_want_this", created_at: 2.months.ago - 1.day)

      # Permitted event (kept regardless of age).
      purchase = purchases(:named_seller_call_purchase)
      permitted = Event.create!(event_name: "purchase", purchase_state: "successful", purchase_id: purchase.id, link_id: purchase.link_id, price_cents: purchase.price_cents, created_at: 2.months.ago - 1.day)

      # Non-permitted event newer than 2 months — kept because outside the [from, to] window.
      kept_because_recent = Event.create!(event_name: "i_want_this", created_at: 1.month.ago)

      DeleteOldUnusedEventsWorker.new.perform
      assert_equal [permitted, kept_because_recent].map(&:id).sort, Event.pluck(:id).sort

      DeleteOldUnusedEventsWorker.new.perform(from: 1.year.ago, to: Time.current)
      assert_equal [permitted.id], Event.pluck(:id)
    end
  end
end
