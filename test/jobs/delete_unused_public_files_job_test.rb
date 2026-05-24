# frozen_string_literal: true

require "test_helper"

class DeleteUnusedPublicFilesJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    skip "ActiveStorage attachments hit S3 (localhost:9000 MinIO) in CI, " \
         "which trips Makara::Errors::BlacklistedWhileInTransaction. " \
         "Re-enable with ActiveStorage::Blob.service stubbed to a local disk service in CI."
  end

  def attach_audio(public_file)
    public_file.file.attach(
      io: File.open(Rails.root.join("spec/support/fixtures/test.mp3")),
      filename: "test.mp3",
      content_type: "audio/mpeg",
    )
    public_file.save!
    public_file
  end

  test "deletes public files scheduled for deletion" do
    public_file = attach_audio(public_files(:scheduled_past))

    DeleteUnusedPublicFilesJob.new.perform

    public_file.reload
    assert public_file.deleted?
    perform_enqueued_jobs
    assert_not public_file.file.attached?
  end

  test "does not delete public files not scheduled for deletion" do
    public_file = attach_audio(public_files(:not_scheduled))
    assert public_file.file.attached?

    DeleteUnusedPublicFilesJob.new.perform

    public_file.reload
    assert_not public_file.deleted?
    assert public_file.file.attached?
  end

  test "does not delete public files scheduled for future deletion" do
    public_file = attach_audio(public_files(:scheduled_future))
    assert public_file.file.attached?

    DeleteUnusedPublicFilesJob.new.perform

    public_file.reload
    assert_not public_file.deleted?
    assert public_file.file.attached?
  end

  test "only deletes the blob if no other attachments reference it" do
    public_file1 = attach_audio(public_files(:scheduled_past))
    public_file2 = public_files(:shared_blob_holder)
    public_file2.file.attach(public_file1.file.blob)
    public_file2.save!
    assert public_file1.file.attached?
    assert public_file2.file.attached?

    DeleteUnusedPublicFilesJob.new.perform
    perform_enqueued_jobs

    public_file1.reload
    public_file2.reload
    assert public_file1.deleted?
    assert public_file1.file.attached?
    assert public_file2.file.attached?
  end

  test "handles transaction rollback if deletion fails" do
    public_file = attach_audio(public_files(:scheduled_past))

    ActiveStorage::Attached::One.define_method(:purge_later) do
      raise ActiveStorage::FileNotFoundError
    end

    assert_raises(ActiveStorage::FileNotFoundError) do
      DeleteUnusedPublicFilesJob.new.perform
    end

    public_file.reload
    assert_not public_file.deleted?
    assert public_file.file.attached?
  ensure
    ActiveStorage::Attached::One.send(:remove_method, :purge_later) rescue nil
  end
end
