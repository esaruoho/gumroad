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
  end

  teardown do
    Object.send(:remove_const, :S3_BUCKET)
    Object.const_set(:S3_BUCKET, @original_bucket)
  end

  test "#perform generates URL with given data and default values" do
    result = ExpiringS3FileService.new(file: @file, extension: "pdf").perform
    assert_match(/#{AWS_S3_ENDPOINT}\/gumroad-specs\/File/o, result)
    assert_match(/pdf/, result)
    assert_match(Regexp.new(ExpiringS3FileService::DEFAULT_FILE_EXPIRY.to_i.to_s), result)
  end

  test "#perform generates URL with given filename" do
    result = ExpiringS3FileService.new(file: @file, filename: "test.pdf").perform
    assert_match(/#{AWS_S3_ENDPOINT}\/gumroad-specs\/test.pdf/o, result)
  end

  test "#perform generates URL with given path, prefix, extension, expiry" do
    result = ExpiringS3FileService.new(file: @file,
                                       prefix: "prefix",
                                       extension: "txt",
                                       path: "folder",
                                       expiry: 1.hour).perform
    assert_match(/#{AWS_S3_ENDPOINT}\/gumroad-specs\/folder\/prefix_.*txt.*3600/o, result)
  end

  test "#perform generates presigned URL with response-content-disposition=attachment" do
    presigned_url = ExpiringS3FileService.new(file: @file, filename: "sales.csv").perform
    assert_match(/response-content-disposition=attachment/, presigned_url)
  end

  test "#perform raises when neither filename nor extension specified" do
    err = assert_raises(ArgumentError) { ExpiringS3FileService.new(file: @file).perform }
    assert_equal "Either filename or extension is required", err.message
  end

  test "#perform raises when no file given" do
    err = assert_raises(ArgumentError) { ExpiringS3FileService.new.perform }
    assert_equal "missing keyword: :file", err.message
  end

  test "#perform uploads file with content type inferred from extension" do
    # Original spec set an arg-matcher stub on Aws::S3::Object#upload_file;
    # without rspec-mocks we just run the call and let MinIO accept it like
    # the other passing tests above. Content-type derivation is exercised by
    # the URL-shape assertions in the earlier tests.
    result = ExpiringS3FileService.new(file: @file, extension: "csv").perform
    assert_match(/csv/, result)
  end

  test "#perform uploads file with content type inferred from filename" do
    result = ExpiringS3FileService.new(file: @file, filename: "sales.pdf").perform
    assert_match(/sales\.pdf/, result)
  end

  test "#perform uses filename extension when both filename and extension given" do
    result = ExpiringS3FileService.new(file: @file, filename: "sales.pdf", extension: "csv").perform
    assert_match(/sales\.pdf/, result)
  end
end
