# frozen_string_literal: true

require "test_helper"

class SubscriptionEventTest < ActiveSupport::TestCase
  setup do
    @subscription = subscriptions(:named_seller_product_subscription)
    @subscription.update_column(:seller_id, users(:named_seller).id) if @subscription.seller_id.nil?
  end

  test "sets the seller from the subscription on create" do
    event = SubscriptionEvent.create!(
      subscription: @subscription, event_type: :deactivated, occurred_at: Time.current
    )
    assert_equal @subscription.seller_id, event.seller_id
    assert_equal @subscription.seller, event.seller
  end

  test "validates consecutive event_type is not duplicated" do
    SubscriptionEvent.create!(subscription: @subscription, event_type: :deactivated, occurred_at: 5.days.ago)
    assert_raises(ActiveRecord::RecordInvalid) do
      SubscriptionEvent.create!(subscription: @subscription, event_type: :deactivated, occurred_at: Time.current)
    end

    SubscriptionEvent.create!(subscription: @subscription, event_type: :restarted, occurred_at: 4.days.ago)
    assert_raises(ActiveRecord::RecordInvalid) do
      SubscriptionEvent.create!(subscription: @subscription, event_type: :restarted, occurred_at: Time.current)
    end

    SubscriptionEvent.create!(subscription: @subscription, event_type: :deactivated, occurred_at: 3.days.ago)
    assert_raises(ActiveRecord::RecordInvalid) do
      SubscriptionEvent.create!(subscription: @subscription, event_type: :deactivated, occurred_at: Time.current)
    end
  end
end
