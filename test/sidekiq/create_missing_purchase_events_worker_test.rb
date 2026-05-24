# frozen_string_literal: true

require "test_helper"

class CreateMissingPurchaseEventsWorkerTest < ActiveSupport::TestCase
  setup do
    @purchase = purchases(:missing_events_yesterday_purchase)
    # Spec expected named_seller to have timezone "UTC"; default is Pacific.
    @purchase.seller.update!(timezone: "UTC")
    RegenerateCreatorAnalyticsCacheWorker.clear
    Event.delete_all
  end

  test "creates the missing event and regenerate cached analytics for that day" do
    CreateMissingPurchaseEventsWorker.new.perform

    event = Event.first!
    attrs = event.attributes.symbolize_keys
    assert_equal "purchase", attrs[:event_name]
    assert_in_delta @purchase.created_at.to_f, attrs[:created_at].to_f, 1
    assert_equal @purchase.purchaser_id, attrs[:user_id]
    assert_equal @purchase.link_id, attrs[:link_id]
    assert_equal @purchase.id, attrs[:purchase_id]
    assert_equal @purchase.price_cents, attrs[:price_cents]
    assert_equal @purchase.purchase_state, attrs[:purchase_state]
    assert_equal @purchase.ip_country, attrs[:ip_country]
    assert_equal @purchase.ip_state, attrs[:ip_state]

    enqueued = RegenerateCreatorAnalyticsCacheWorker.jobs.map { |j| j["args"] }
    assert_includes enqueued, [@purchase.seller_id, Date.yesterday.to_s]
  end

  test "does not create another event if it already exists" do
    Event.create!(event_name: "purchase", link_id: @purchase.link_id, purchase_id: @purchase.id)

    CreateMissingPurchaseEventsWorker.new.perform

    assert_equal 1, Event.count
    assert_equal 0, RegenerateCreatorAnalyticsCacheWorker.jobs.size
  end
end
