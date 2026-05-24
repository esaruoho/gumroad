# frozen_string_literal: true

require "test_helper"

class SignedUrlHelperTest < ActiveSupport::TestCase
  include SignedUrlHelper

  PDF_PATH = "attachments/23b2d41ac63a40b5afa1a99bf38a0982/original/nyt.pdf"
  TEST_S3_BUCKET = "gumroad-specs"
  TEST_S3_BASE_URL = "https://s3.amazonaws.com/gumroad-specs/"

  setup do
    @file = product_files(:signed_url_helper_pdf)
    @pdf_uri = "#{S3_BASE_URL}#{PDF_PATH}"

    @s3_object = Object.new
    @s3_object.define_singleton_method(:public_url) { SignedUrlHelperTest.const_get(:PDF_URI) rescue nil }
    pdf_uri = @pdf_uri
    @s3_object.define_singleton_method(:public_url) { pdf_uri }

    s3_object = @s3_object
    bucket = Object.new
    bucket.define_singleton_method(:object) { |*_| s3_object }
    s3_resource = Object.new
    s3_resource.define_singleton_method(:bucket) { |*_| bucket }

    response = Object.new
    contents = Object.new
    contents.define_singleton_method(:map) { |&_blk| [PDF_PATH] }
    response.define_singleton_method(:contents) { contents }

    s3_client = Object.new
    s3_client.define_singleton_method(:list_objects) { |*_| [response] }

    @original_s3_resource_new = Aws::S3::Resource.method(:new)
    @original_s3_client_new = Aws::S3::Client.method(:new)
    Aws::S3::Resource.define_singleton_method(:new) { |*_args, **_kw| s3_resource }
    Aws::S3::Client.define_singleton_method(:new) { |*_args, **_kw| s3_client }

    Rails.cache.clear
    $redis.del(RedisKey.cf_cache_invalidated_extensions_and_cache_keys)
  end

  teardown do
    Aws::S3::Resource.singleton_class.send(:remove_method, :new) rescue nil
    Aws::S3::Resource.define_singleton_method(:new, @original_s3_resource_new) if @original_s3_resource_new
    Aws::S3::Client.singleton_class.send(:remove_method, :new) rescue nil
    Aws::S3::Client.define_singleton_method(:new, @original_s3_client_new) if @original_s3_client_new
    $redis.del(RedisKey.cf_cache_invalidated_extensions_and_cache_keys)
    Rails.cache.delete("set_cf_worker_cache_keys_from_redis")
  end

  # --- minio path ---

  test "returns a minio presigned url" do
    presigned_url = "#{@pdf_uri}?X-Amz-Signature=test"
    @s3_object.define_singleton_method(:content_length) { 1000 }
    expected_filename = @file.s3_filename
    @s3_object.define_singleton_method(:presigned_url) do |verb, **opts|
      raise "unexpected" unless verb == :get && opts[:expires_in] == 10.minutes.to_i &&
                                opts[:response_content_disposition] == "attachment; filename=\"#{expected_filename}\""
      presigned_url
    end
    assert_equal presigned_url, signed_download_url_for_s3_key_and_filename(@file.s3_key, @file.s3_filename)
  end

  # --- non-minio path ---

  def with_non_minio(&block)
    with_const(:USING_MINIO, false) do
      with_const(:CLOUDFRONT_DOWNLOAD_DISTRIBUTION_URL, "https://cloudfront.net/") do
        with_const(:FILE_DOWNLOAD_DISTRIBUTION_URL, "https://staging-files.gumroad.com/", &block)
      end
    end
  end

  test "returns the correct validation duration" do
    with_non_minio do
      assert_equal SignedUrlHelper::SIGNED_S3_URL_VALID_FOR_MINIMUM, signed_url_validity_time_for_file_size(10)
      assert_equal SignedUrlHelper::SIGNED_S3_URL_VALID_FOR_MAXIMUM, signed_url_validity_time_for_file_size(1_000_000_000)
      assert_equal (200_000_000 / 1_024 / 50).seconds, signed_url_validity_time_for_file_size(200_000_000)
    end
  end

  test "returns a CloudFront read url with cache_group param if file size >= 8GB" do
    with_non_minio do
      @s3_object.define_singleton_method(:content_length) { 8_000_000_000 }
      url = signed_download_url_for_s3_key_and_filename(@file.s3_key, @file.s3_filename, cache_group: "read")
      assert_match(/cloudfront\.net.*cache_group=read/, url)
    end
  end

  test "returns a Cloudflare read url with cache_group param if file size < 8GB" do
    with_non_minio do
      @s3_object.define_singleton_method(:content_length) { 1_000_000_000 }
      url = signed_download_url_for_s3_key_and_filename(@file.s3_key, @file.s3_filename, cache_group: "read")
      assert_match(/staging-files\.gumroad\.com.*cache_group=read.*verify=/, url)
    end
  end

  test "contains the cache_key parameter for files with specific extensions" do
    with_non_minio do
      with_const(:S3_BUCKET, TEST_S3_BUCKET) do
        with_const(:S3_BASE_URL, TEST_S3_BASE_URL) do
          @s3_object.define_singleton_method(:content_length) { 1_000_000_000 }
          url = signed_download_url_for_s3_key_and_filename(@file.s3_key, @file.s3_filename)
          assert_not_includes url, "cache_key=caIWHGT4Qhqo6KoxDMNXwQ"

          %w(jpg jpeg png epub brushset scrivtemplate zip).each do |extension|
            file_path = "#{TEST_S3_BASE_URL}attachments/23b2d41ac63a40b5afa1a99bf38a0982/original/nyt.#{extension}"
            file = ProductFile.create!(link_id: @file.link_id, url: file_path)
            ext_url = signed_download_url_for_s3_key_and_filename(file.s3_key, file.s3_filename)
            assert_match(/staging-files\.gumroad\.com.*cache_key=caIWHGT4Qhqo6KoxDMNXwQ.*/, ext_url)
          end
        end
      end
    end
  end

  test "raises a descriptive exception if the S3 object doesn't exist" do
    with_non_minio do
      with_const(:S3_BUCKET, TEST_S3_BUCKET) do
        # Restore real Aws::S3 lookups so this hits the real (mocked-out) path.
        Aws::S3::Resource.singleton_class.send(:remove_method, :new) rescue nil
        Aws::S3::Resource.define_singleton_method(:new, @original_s3_resource_new)
        Aws::S3::Client.singleton_class.send(:remove_method, :new) rescue nil
        Aws::S3::Client.define_singleton_method(:new, @original_s3_client_new)

        WebMock.stub_request(:any, /amazonaws\.com/).to_return(status: 404, body: "")
        WebMock.stub_request(:any, %r{localhost:9000}).to_return(status: 404, body: "")

        err = assert_raises(Aws::S3::Errors::NotFound) do
          signed_download_url_for_s3_key_and_filename("attachments/missing.txt", "filename")
        end
        assert_match(/Key = attachments\/missing.txt/, err.message)
      end
    end
  end

  # --- file_needs_cache_key? / cf_worker_cache_extensions_and_keys / cf_cache_key ---

  test "file_needs_cache_key? returns true when cache key is needed" do
    with_non_minio { assert send(:file_needs_cache_key?, "file.jpg") }
  end

  test "file_needs_cache_key? returns false when cache key is not needed" do
    with_non_minio { assert_not send(:file_needs_cache_key?, "file.mp3") }
  end

  test "cf_worker_cache_extensions_and_keys returns a hash" do
    with_non_minio do
      h = send(:cf_worker_cache_extensions_and_keys)
      assert_kind_of Hash, h
      assert_equal "caIWHGT4Qhqo6KoxDMNXwQ", h[".jpg"]
    end
  end

  test "cf_cache_key returns the key when configured" do
    with_non_minio { assert_equal "caIWHGT4Qhqo6KoxDMNXwQ", send(:cf_cache_key, "filename.zip") }
  end

  test "cf_cache_key returns nil when not configured" do
    with_non_minio { assert_nil send(:cf_cache_key, "filename.mp3") }
  end

  test "overrides cache key with the key from Redis" do
    with_non_minio do
      assert_equal "caIWHGT4Qhqo6KoxDMNXwQ", send(:cf_worker_cache_extensions_and_keys)[".jpg"]

      $redis.hset(RedisKey.cf_cache_invalidated_extensions_and_cache_keys, ".jpg", Digest::SHA1.hexdigest("2020-10-09"))
      Rails.cache.delete("set_cf_worker_cache_keys_from_redis")

      assert_equal Digest::SHA1.hexdigest("2020-10-09"), send(:cf_worker_cache_extensions_and_keys)[".jpg"]
    end
  end

  test "uses Rails.cache to read the value from Redis only once" do
    with_non_minio do
      assert_nil send(:cf_worker_cache_extensions_and_keys)[".mp3"]
      $redis.hset(RedisKey.cf_cache_invalidated_extensions_and_cache_keys, ".mp4", Digest::SHA1.hexdigest("2020-10-09"))
      assert_nil send(:cf_worker_cache_extensions_and_keys)[".mp3"]
    end
  end
end
