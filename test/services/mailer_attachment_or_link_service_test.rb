# frozen_string_literal: true

require "test_helper"

class MailerAttachmentOrLinkServiceTest < ActiveSupport::TestCase
  setup do
    # 32 bytes — well below MAX_FILE_SIZE (10 MB).
    @small_file = Tempfile.new(["mailer-attach", ".csv"])
    @small_file.binmode
    @small_file.write("hello,world\n" * 2)
    @small_file.rewind
  end

  teardown do
    @small_file.close
    @small_file.unlink
  end

  test "#perform returns the original file when size is <= MAX_FILE_SIZE" do
    result = MailerAttachmentOrLinkService.new(file: @small_file, extension: "csv").perform
    assert_equal @small_file, result[:file]
    assert_nil result[:url]
  end

  test "#perform returns the original file when size is exactly MAX_FILE_SIZE" do
    @small_file.define_singleton_method(:size) { MailerAttachmentOrLinkService::MAX_FILE_SIZE }
    result = MailerAttachmentOrLinkService.new(file: @small_file, extension: "csv").perform
    assert_equal @small_file, result[:file]
    assert_nil result[:url]
  end

  test "#perform delegates to ExpiringS3FileService when file size exceeds MAX_FILE_SIZE" do
    @small_file.define_singleton_method(:size) { MailerAttachmentOrLinkService::MAX_FILE_SIZE + 1 }

    captured = {}
    fake = Object.new
    fake.define_singleton_method(:perform) { "https://signed.example.com/file.csv" }

    orig = ExpiringS3FileService.method(:new)
    ExpiringS3FileService.define_singleton_method(:new) do |**kwargs|
      captured.merge!(kwargs)
      fake
    end
    begin
      result = MailerAttachmentOrLinkService.new(file: @small_file, filename: "report.csv", extension: "csv").perform
    ensure
      ExpiringS3FileService.define_singleton_method(:new, orig) if orig
    end

    assert_nil result[:file]
    assert_equal "https://signed.example.com/file.csv", result[:url]
    assert_equal @small_file, captured[:file]
    assert_equal "csv", captured[:extension]
    assert_equal "report.csv", captured[:filename]
  end
end
