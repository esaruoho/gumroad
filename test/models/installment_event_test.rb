require "test_helper"

class InstallmentEventTest < ActiveSupport::TestCase
  fixtures :installments

  test "queues update of Installment's installment_events_count on create" do
    UpdateInstallmentEventsCountCacheWorker.jobs.clear
    installment = installments(:published_post)
    event = Event.create!(event_name: "post_view")
    InstallmentEvent.create!(installment: installment, event: event)
    enqueued_ids = UpdateInstallmentEventsCountCacheWorker.jobs.map { |j| j["args"].first }
    assert_includes enqueued_ids, installment.id
  end
end
