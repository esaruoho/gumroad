# frozen_string_literal: true

require "test_helper"

class ChargeSuccessfulPreordersWorkerTest < ActiveSupport::TestCase
  setup do
    ChargePreorderWorker.clear
    SendPreorderSellerSummaryWorker.clear
  end

  test "enqueues a ChargePreorderWorker for each authorization-successful preorder" do
    preorder_link = preorder_links(:preorder_test_link)
    successful = preorders(:preorder_successful)

    ChargeSuccessfulPreordersWorker.new.perform(preorder_link.id)

    enqueued_ids = ChargePreorderWorker.jobs.map { |j| j["args"].first }
    assert_includes enqueued_ids, successful.id
    refute_includes enqueued_ids, preorders(:preorder_failed).id
    refute_includes enqueued_ids, preorders(:preorder_charged).id
  end

  test "schedules a Sidekiq job to send preorder seller summary" do
    preorder_link = preorder_links(:preorder_test_link)

    ChargeSuccessfulPreordersWorker.new.perform(preorder_link.id)

    enqueued_ids = SendPreorderSellerSummaryWorker.jobs.map { |j| j["args"].first }
    assert_includes enqueued_ids, preorder_link.id
  end
end
