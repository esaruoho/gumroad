# frozen_string_literal: true

require "test_helper"

class Radar::SyncValueListsJobTest < ActiveSupport::TestCase
  test "is enqueued in the low queue" do
    assert_equal "low", Radar::SyncValueListsJob.sidekiq_options["queue"]
  end

  test "calls sync_blocked_emails and sync_blocked_cards on the service" do
    service = Minitest::Mock.new
    service.expect(:sync_blocked_emails, nil)
    service.expect(:sync_blocked_cards, nil)

    Radar::ValueListSyncService.stub(:new, service) do
      Radar::SyncValueListsJob.new.perform
    end

    assert service.verify
  end
end
