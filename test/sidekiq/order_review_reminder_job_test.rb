# frozen_string_literal: true

require "test_helper"

class OrderReviewReminderJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  setup do
    @order = orders(:admin_charge_policy_order)
    @eligible = Struct.new(:id, :eligible).new(101, true)
    @eligible.define_singleton_method(:eligible_for_review_reminder?) { eligible }
    @ineligible = Struct.new(:id, :eligible).new(102, false)
    @ineligible.define_singleton_method(:eligible_for_review_reminder?) { eligible }
    @another_eligible = Struct.new(:id, :eligible).new(103, true)
    @another_eligible.define_singleton_method(:eligible_for_review_reminder?) { eligible }

    @purchases_for_order = []
    order = @order
    purchases_for_order = -> { @purchases_for_order }
    @order_mod = Module.new
    @order_mod.send(:define_method, :find) do |id|
      id == order.id ? order : super(id)
    end
    Order.singleton_class.prepend(@order_mod)

    # override Order#purchases on the specific instance
    @order.define_singleton_method(:purchases) { purchases_for_order.call }
  end

  test "does not enqueue any emails when there are no eligible purchases" do
    @purchases_for_order = [@ineligible]

    assert_no_enqueued_emails do
      OrderReviewReminderJob.new.perform(@order.id)
    end
  end

  test "enqueues a single purchase review reminder once" do
    @purchases_for_order = [@eligible, @ineligible]

    assert_enqueued_emails 1 do
      OrderReviewReminderJob.new.perform(@order.id)
      OrderReviewReminderJob.new.perform(@order.id)
    end

    enqueued = ActionMailer::Base.deliveries + ActiveJob::Base.queue_adapter.enqueued_jobs
    job = ActiveJob::Base.queue_adapter.enqueued_jobs.find { |j| j[:args].any? { |a| a == "purchase_review_reminder" || (a.is_a?(Hash) && a["method_name"] == "purchase_review_reminder") } }
    assert job, "Expected purchase_review_reminder enqueued"
  end

  test "enqueues an order review reminder once when multiple eligible purchases" do
    @purchases_for_order = [@eligible, @another_eligible]

    assert_enqueued_emails 1 do
      OrderReviewReminderJob.new.perform(@order.id)
      OrderReviewReminderJob.new.perform(@order.id)
    end

    job = ActiveJob::Base.queue_adapter.enqueued_jobs.find { |j| j[:args].any? { |a| a == "order_review_reminder" || (a.is_a?(Hash) && a["method_name"] == "order_review_reminder") } }
    assert job, "Expected order_review_reminder enqueued"
  end
end
