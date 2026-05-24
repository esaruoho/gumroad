# frozen_string_literal: true

require "test_helper"

class DeleteUnusedPublicFilesJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # Run outside the default test transaction so ActiveStorage's after-commit
  # purge_later callbacks fire (and so Makara doesn't blacklist the connection
  # when ActiveStorage talks to its service).
  self.use_transactional_tests = false

  setup do
    require "active_storage/service/disk_service"
    @storage_root = Rails.root.join("tmp/storage_test_#{SecureRandom.hex(4)}")
    @disk_service = ActiveStorage::Service::DiskService.new(root: @storage_root)
    @disk_service.name = :local_test
    # Register in the service registry so Blob.service_name validation passes.
    services = ActiveStorage::Blob.services.instance_variable_get(:@services)
    @registered_prev = services[:local_test]
    services[:local_test] = @disk_service
    @original_service = ActiveStorage::Blob.service
    ActiveStorage::Blob.service = @disk_service
  end

  teardown do
    ActiveStorage::Blob.service = @original_service if @original_service
    services = ActiveStorage::Blob.services.instance_variable_get(:@services)
    if @registered_prev
      services[:local_test] = @registered_prev
    else
      services.delete(:local_test)
    end
    FileUtils.rm_rf(@storage_root) if @storage_root
    PublicFile.unscoped.delete_all
    ActiveStorage::Attachment.unscoped.delete_all
    ActiveStorage::Blob.unscoped.delete_all
  end

  def attach_audio(public_file)
    public_file.file.attach(
      io: File.open(Rails.root.join("spec/support/fixtures/test.mp3")),
      filename: "test.mp3",
      content_type: "audio/mpeg",
    )
    unless public_file.save
      raise "save failed: #{public_file.errors.full_messages.inspect}"
    end
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
