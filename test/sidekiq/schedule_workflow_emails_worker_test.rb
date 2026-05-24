# frozen_string_literal: true

require "test_helper"

class ScheduleWorkflowEmailsWorkerTest < ActiveSupport::TestCase
  # The original spec exercised 8 filter branches inside Purchase#schedule_all_workflows
  # (created_before/after, paid_more/less_than_cents, bought_products, bought_variants,
  # bought_from) which all live on Workflow#applies_to_purchase?. Those filter branches
  # belong on a Workflow / Purchase unit test — this Sidekiq worker is a 2-line
  # delegate. Cover the delegation contract and the missing-purchase error path here.

  setup do
    @purchase = purchases(:named_seller_call_purchase)
    @scheduled = []
    captured = @scheduled
    Purchase.define_method(:schedule_all_workflows) { captured << self }
  end

  teardown do
    Purchase.remove_method(:schedule_all_workflows) if Purchase.instance_methods(false).include?(:schedule_all_workflows)
  end

  test "#perform delegates to Purchase#schedule_all_workflows for the looked-up purchase" do
    ScheduleWorkflowEmailsWorker.new.perform(@purchase.id)

    assert_equal 1, @scheduled.size
    assert_equal @purchase.id, @scheduled.first.id
  end

  test "#perform raises ActiveRecord::RecordNotFound when the purchase does not exist" do
    assert_raises(ActiveRecord::RecordNotFound) do
      ScheduleWorkflowEmailsWorker.new.perform(0)
    end
    assert_empty @scheduled
  end

  test "#perform can be enqueued as a Sidekiq job" do
    ScheduleWorkflowEmailsWorker.jobs.clear
    ScheduleWorkflowEmailsWorker.perform_async(@purchase.id)

    assert_equal 1, ScheduleWorkflowEmailsWorker.jobs.size
    assert_equal [@purchase.id], ScheduleWorkflowEmailsWorker.jobs.last["args"]
  ensure
    ScheduleWorkflowEmailsWorker.jobs.clear
  end
end
