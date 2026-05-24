# frozen_string_literal: true

require "test_helper"

class DeleteOldSentEmailInfoRecordsJobTest < ActiveSupport::TestCase
  test "deletes targeted rows" do
    assert_equal 3, SentEmailInfo.count

    DeleteOldSentEmailInfoRecordsJob.new.perform

    assert_equal 1, SentEmailInfo.count
    assert SentEmailInfo.exists?(key: "sent-email-info-recent")
  end

  test "does not fail when there are no records" do
    SentEmailInfo.delete_all
    assert_nil DeleteOldSentEmailInfoRecordsJob.new.perform
  end
end
