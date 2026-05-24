# frozen_string_literal: true

require "test_helper"

class ExpiringS3FileServiceTest < ActiveSupport::TestCase
  setup do
    @file = Rack::Test::UploadedFile.new(
      Rails.root.join("spec", "support", "fixtures", "test.png"),
      "image/png"
    )
    @original_bucket = S3_BUCKET
    Object.send(:remove_const, :S3_BUCKET)
    Object.const_set(:S3_BUCKET, "gumroad-specs")

    @uploaded = []
    uploaded = @uploaded

    @orig_upload = Aws::S3::Object.instance_method(:upload_file)
    Aws::S3::Object.define_method(:upload_file) do |file, **opts|
      uploaded << { key:, file:, content_type: opts[:content_type] }
      true
    end

    @orig_presigned_url = Aws::S3::Object.instance_method(:presigned_url)
    Aws::S3::Object.define_method(:presigned_url) do |method, **opts|
      "#{AWS_S3_ENDPOINT}/#{bucket_name}/#{key}?X-Amz-Expires=#{opts[:expires_in]}&response-content-disposition=#{opts[:response_content_disposition]}"
    end
  end

  teardown do
    Object.send(:remove_const, :S3_BUCKET)
    Object.const_set(:S3_BUCKET, @original_bucket)
    Aws::S3::Object.define_method(:upload_file, @orig_upload) if @orig_upload
    Aws::S3::Object.define_method(:presigned_url, @orig_presigned_url) if @orig_presigned_url
  end

  test "#perform generates URL with given data and default values" do
    result = ExpiringS3FileService.new(file: @file, extension: "pdf").perform
    assert_match(/#{AWS_S3_ENDPOINT}\/gumroad-specs\/File/o, result)
    assert_match(/pdf/, result)
    assert_match Regexp.new(ExpiringS3FileService::DEFAULT_FILE_EXPIRY.to_i.to_s), result
  end

  test "#perform generates URL with given filename" do
    result = ExpiringS3FileService.new(file: @file, filename: "test.pdf").perform
    assert_match(/#{AWS_S3_ENDPOINT}\/gumroad-specs\/test.pdf/o, result)
  end

  test "#perform generates URL with given path, prefix, extension, expiry" do
    result = ExpiringS3FileService.new(file: @file, prefix: "prefix",
                                       extension: "txt", path: "folder", expiry: 1.hour).perform
    assert_match(/#{AWS_S3_ENDPOINT}\/gumroad-specs\/folder\/prefix_.*txt.*3600/o, result)
  end

  test "#perform generates presigned URL with attachment disposition" do
    result = ExpiringS3FileService.new(file: @file, filename: "sales.csv").perform
    assert_match(/response-content-disposition=attachment/, result)
  end

  test "raises if specified without filename and extension" do
    e = assert_raises(ArgumentError) { ExpiringS3FileService.new(file: @file).perform }
    assert_equal "Either filename or extension is required", e.message
  end

  test "raises if file not provided" do
    assert_raises(ArgumentError) { ExpiringS3FileService.new.perform }
  end

  test "uses content type inferred from extension" do
    ExpiringS3FileService.new(file: @file, extension: "csv").perform
    assert_equal "text/csv", @uploaded.last[:content_type]
  end

  test "uses content type inferred from filename" do
    ExpiringS3FileService.new(file: @file, filename: "sales.pdf").perform
    assert_equal "application/pdf", @uploaded.last[:content_type]
  end

  test "filename wins over extension for content type" do
    ExpiringS3FileService.new(file: @file, filename: "sales.pdf", extension: "csv").perform
    assert_equal "application/pdf", @uploaded.last[:content_type]
  end
end
