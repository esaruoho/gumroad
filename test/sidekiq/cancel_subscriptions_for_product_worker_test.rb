# frozen_string_literal: true

require "test_helper"

class CancelSubscriptionsForProductWorkerTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @product = links(:cancel_subs_deleted_membership)
    @subscription = subscriptions(:cancel_subs_active_subscription)
  end

  test "cancels the subscriptions" do
    assert @subscription.alive?

    CancelSubscriptionsForProductWorker.new.perform(@product.id)

    refute @subscription.reload.alive?
  end

  test "sends out the email" do
    assert_enqueued_email_with(ContactingCreatorMailer, :subscription_product_deleted, args: [@product.id], queue: "critical") do
      CancelSubscriptionsForProductWorker.new.perform(@product.id)
    end
  end

  test "doesn't cancel the subscriptions for a published product" do
    @product.update_columns(deleted_at: nil, purchase_disabled_at: nil, draft: false)
    assert @subscription.alive?

    CancelSubscriptionsForProductWorker.new.perform(@product.id)

    assert @subscription.reload.alive?
  end
end
