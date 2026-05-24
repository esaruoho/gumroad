# frozen_string_literal: true

require "test_helper"

class OrderReviewReminderJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @order = orders(:invoice_seller_order)

    @eligible_purchase = make_purchase_double(id: 101, eligible: true)
    @ineligible_purchase = make_purchase_double(id: 102, eligible: false)
    @another_eligible = make_purchase_double(id: 103, eligible: true)
  end

  def make_purchase_double(id:, eligible:)
    p = Object.new
    p.define_singleton_method(:id) { id }
    p.define_singleton_method(:eligible_for_review_reminder?) { eligible }
    p
  end

  def run_with_purchases(purchases)
    order = @order
    purchases_list = purchases
    order_proxy = Object.new
    order_proxy.define_singleton_method(:purchases) { purchases_list }
    order_proxy.define_singleton_method(:id) { order.id }
    Order.stub(:find, ->(id) { id == order.id ? order_proxy : Order.find(id) }) do
      yield
    end
  end

  test "does not enqueue any emails when there are no eligible purchases" do
    run_with_purchases([@ineligible_purchase]) do
      assert_no_enqueued_emails do
        OrderReviewReminderJob.new.perform(@order.id)
      end
    end
  end

  test "enqueues a single purchase review reminder once when one eligible purchase" do
    run_with_purchases([@eligible_purchase, @ineligible_purchase]) do
      assert_enqueued_emails 1 do
        OrderReviewReminderJob.new.perform(@order.id)
        OrderReviewReminderJob.new.perform(@order.id)
      end
    end

    assert_enqueued_email_with CustomerLowPriorityMailer, :purchase_review_reminder, args: [@eligible_purchase.id], queue: "low"
  end

  test "enqueues an order review reminder once when multiple eligible purchases" do
    run_with_purchases([@eligible_purchase, @another_eligible]) do
      assert_enqueued_emails 1 do
        OrderReviewReminderJob.new.perform(@order.id)
        OrderReviewReminderJob.new.perform(@order.id)
      end
    end

    assert_enqueued_email_with CustomerLowPriorityMailer, :order_review_reminder, args: [@order.id], queue: "low"
  end
end
