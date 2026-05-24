# frozen_string_literal: true

require "test_helper"

class SslCertificates::BaseTest < ActiveSupport::TestCase
  setup do
    @original_config_file = SslCertificates::Base::CONFIG_FILE
    SslCertificates::Base.send(:remove_const, :CONFIG_FILE)
    SslCertificates::Base.const_set(
      :CONFIG_FILE,
      Rails.root.join("spec", "support", "fixtures", "ssl_certificates.yml.erb")
    )
    @obj = SslCertificates::Base.new
  end

  teardown do
    SslCertificates::Base.send(:remove_const, :CONFIG_FILE)
    SslCertificates::Base.const_set(:CONFIG_FILE, @original_config_file)
  end

  test ".supported_environment? returns true when production" do
    Rails.env.stub(:production?, true) do
      assert_equal true, SslCertificates::Base.supported_environment?
    end
  end

  test ".supported_environment? returns false in non-prod/staging" do
    assert_equal false, SslCertificates::Base.supported_environment?
  end

  test "#initialize sets the required config variables as methods" do
    assert_equal "test-service-letsencrypt@gumroad.com", @obj.send(:account_email)
    assert_equal "https://test.api.letsencrypt.org/directory", @obj.send(:acme_url)
    assert_equal 8.hours.seconds, @obj.send(:invalid_domain_cache_expires_in)
    assert_equal 10, @obj.send(:max_retries)
    assert_equal 300, @obj.send(:rate_limit)
    assert_equal 3.hours.seconds, @obj.send(:rate_limit_hours)
    assert_equal 60.days.seconds, @obj.send(:renew_in)
    assert_equal 2.seconds, @obj.send(:sleep_duration)
    assert_equal "test", @obj.send(:ssl_env)
  end

  test "#certificate_authority returns the certificate authority class" do
    assert_equal SslCertificates::LetsEncrypt, @obj.send(:certificate_authority)
  end

  test "#ssl_file_path returns the S3 SSL file path" do
    assert_equal "custom-domains-ssl/test/sample.com/ssl/sample",
                 @obj.ssl_file_path("sample.com", "sample")
  end

  test "#delete_from_s3 deletes the object at the given key" do
    s3_key = "custom-domains-ssl/test/www.example.com/public/sample_challenge_file"
    deleted_keys = []
    s3_object = Object.new
    s3_object.define_singleton_method(:delete) { deleted_keys << :called }
    s3_bucket = Object.new
    s3_bucket.define_singleton_method(:object) do |key|
      raise "unexpected key #{key}" unless key == s3_key
      s3_object
    end
    s3_client = Object.new
    s3_client.define_singleton_method(:bucket) do |bucket_name|
      raise "unexpected bucket #{bucket_name}" unless bucket_name == SslCertificates::Base::SECRETS_S3_BUCKET
      s3_bucket
    end

    Aws::InstanceProfileCredentials.stub(:new, Object.new) do
      Aws::S3::Resource.stub(:new, ->(**_) { s3_client }) do
        @obj.send(:delete_from_s3, s3_key)
      end
    end

    assert_equal [:called], deleted_keys
  end

  test "#write_to_s3 puts content at the given key" do
    test_key = "test_key"
    test_content = "test_content"
    put_args = []
    s3_object = Object.new
    s3_object.define_singleton_method(:put) { |body:| put_args << body }
    s3_bucket = Object.new
    s3_bucket.define_singleton_method(:object) do |key|
      raise "unexpected key #{key}" unless key == test_key
      s3_object
    end
    s3_client = Object.new
    s3_client.define_singleton_method(:bucket) do |bucket_name|
      raise "unexpected bucket #{bucket_name}" unless bucket_name == SslCertificates::Base::SECRETS_S3_BUCKET
      s3_bucket
    end

    Aws::InstanceProfileCredentials.stub(:new, Object.new) do
      Aws::S3::Resource.stub(:new, ->(**_) { s3_client }) do
        @obj.send(:write_to_s3, test_key, test_content)
      end
    end

    assert_equal [test_content], put_args
  end
end
