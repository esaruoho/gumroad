# frozen_string_literal: true

require "test_helper"

class DeleteOldVersionsRecordsWorkerTest < ActiveSupport::TestCase
  test "deletes targeted rows" do
    PaperTrail::Version.delete_all
    20.times do |i|
      PaperTrail::Version.create!(item_type: "User", item_id: i + 1, event: "create", created_at: Time.current)
    end
    assert_equal 20, PaperTrail::Version.count

    stub_const(DeleteOldVersionsRecordsWorker, :MAX_ALLOWED_ROWS, 8) do
      stub_const(DeleteOldVersionsRecordsWorker, :DELETION_BATCH_SIZE, 1) do
        DeleteOldVersionsRecordsWorker.new.perform
      end
    end
    assert_equal 8, PaperTrail::Version.count
  end

  test "does not fail when there are no version records" do
    PaperTrail::Version.delete_all
    assert_nil DeleteOldVersionsRecordsWorker.new.perform
  end
end
