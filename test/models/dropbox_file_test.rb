# frozen_string_literal: true

require "test_helper"

class DropboxFileTest < ActiveSupport::TestCase
  # ---- validations ----

  test "does not allow you to create a dropbox file without a dropbox url" do
    dropbox_file = DropboxFile.new(dropbox_url: nil)
    assert_equal false, dropbox_file.valid?
  end

  # ---- callbacks: #schedule_dropbox_file_analyze ----

  test "enqueues the job to transfer the file to S3 on create" do
    TransferDropboxFileToS3Worker.jobs.clear
    DropboxFile.create!(dropbox_url: "https://www.dropbox.com/file.pdf", state: "in_progress")
    job = TransferDropboxFileToS3Worker.jobs.last
    assert_not_nil job
    assert_kind_of Integer, job["args"].first
  end

  # ---- #validate_dropbox_url! ----

  VALID_DROPBOX_URLS = [
    "https://dl.dropboxusercontent.com/file.pdf",
    "https://ucb7c756cf63e5782670af26c1c4.dl.dropboxusercontent.com/file.pdf",
    "https://www.dropbox.com/file.pdf",
    "https://dropbox.com/file.pdf",
  ].freeze

  INVALID_DROPBOX_URLS = [
    "https://evil.com/dropbox.com/file.pdf",
    "https://dropbox.com.evil.com/file.pdf",
    "https://evil-dropboxusercontent.com/file.pdf",
    "https://127.0.0.1/file.pdf",
    "https://169.254.169.254/latest/meta-data/",
    "http://dl.dropboxusercontent.com/file.pdf",
  ].freeze

  test "#validate_dropbox_url! allows valid Dropbox URLs" do
    VALID_DROPBOX_URLS.each do |url|
      df = DropboxFile.new(dropbox_url: url, state: "in_progress")
      df.send(:validate_dropbox_url!) # should not raise
    end
  end

  test "#validate_dropbox_url! rejects non-Dropbox URLs" do
    INVALID_DROPBOX_URLS.each do |url|
      df = DropboxFile.new(dropbox_url: url, state: "in_progress")
      err = assert_raises(ArgumentError) { df.send(:validate_dropbox_url!) }
      assert_equal "Invalid Dropbox URL", err.message
    end
  end

  # NOTE: the original spec contained a `:vcr` test exercising
  # `multipart_transfer_to_s3` which hits both the Dropbox HTTP API and S3
  # directly (with a real recorded cassette). Migrating that path requires
  # WebMock + S3 stubs that are out of scope for a fixtures-only model spec
  # migration. Logged in /tmp/mig-b-skipped.md.
end
