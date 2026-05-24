# frozen_string_literal: true

require "test_helper"

class SslCertificates::LetsEncryptTest < ActiveSupport::TestCase
  CONFIG_FIXTURE = Rails.root.join("spec", "support", "fixtures", "ssl_certificates.yml.erb").to_s

  setup do
    @original_config_file = SslCertificates::Base.const_get(:CONFIG_FILE)
    SslCertificates::Base.send(:remove_const, :CONFIG_FILE)
    SslCertificates::Base.const_set(:CONFIG_FILE, CONFIG_FIXTURE)

    @custom_domain = custom_domains(:ssl_www_example)
    @obj = SslCertificates::LetsEncrypt.new(@custom_domain.domain)
  end

  teardown do
    SslCertificates::Base.send(:remove_const, :CONFIG_FILE)
    SslCertificates::Base.const_set(:CONFIG_FILE, @original_config_file)
  end

  test "inherits from SslCertificates::Base" do
    assert_operator SslCertificates::LetsEncrypt, :<, SslCertificates::Base
  end

  test "#initialize stores domain" do
    assert_equal @custom_domain.domain, @obj.send(:domain)
  end

  test "certificate_private_key returns an RSA key" do
    assert_equal OpenSSL::PKey::RSA, @obj.send(:certificate_private_key).class
  end

  test "certificate_private_key is 2048 bits" do
    assert_equal 2048, @obj.certificate_private_key.n.num_bits
  end

  test "#upload_certificate_to_s3 writes key and cert to S3" do
    sample_path = "/sample/path"
    @obj.define_singleton_method(:ssl_file_path) { |*| sample_path }

    writes = []
    @obj.define_singleton_method(:write_to_s3) { |path, body| writes << [path, body] }

    @obj.send(:upload_certificate_to_s3, "cert 123", "key 123")

    assert_equal [[sample_path, "cert 123"], [sample_path, "key 123"]], writes
  end

  test "#finalize_with_csr finalizes order and returns certificate" do
    certificate_double = Object.new
    order_double = Object.new
    order_double.define_singleton_method(:status) { "processed" }
    order_double.define_singleton_method(:certificate) { certificate_double }
    finalize_args = nil
    order_double.define_singleton_method(:finalize) { |**kwargs| finalize_args = kwargs }

    csr_double = Object.new
    original_new = Acme::Client::CertificateRequest.method(:new)
    Acme::Client::CertificateRequest.define_singleton_method(:new) { |*_args, **_kwargs| csr_double }

    begin
      result = @obj.send(:finalize_with_csr, order_double, Object.new)
    ensure
      Acme::Client::CertificateRequest.singleton_class.send(:remove_method, :new)
      Acme::Client::CertificateRequest.define_singleton_method(:new, original_new)
    end

    assert_equal certificate_double, result
    assert_equal({ csr: csr_double }, finalize_args)
  end

  test "#poll_validation_status polls max_retries times" do
    http_challenge = Object.new
    status_calls = 0
    reload_calls = 0
    http_challenge.define_singleton_method(:status) { status_calls += 1; "pending" }
    http_challenge.define_singleton_method(:reload) { reload_calls += 1 }

    sleep_calls = 0
    @obj.define_singleton_method(:sleep) { |*| sleep_calls += 1 }

    @obj.send(:poll_validation_status, http_challenge)

    expected = @obj.send(:max_retries)
    assert_equal expected, status_calls
    assert_equal expected, reload_calls
    assert_equal expected, sleep_calls
  end

  test "#request_validation calls request_validation on challenge" do
    http_challenge = Minitest::Mock.new
    http_challenge.expect(:request_validation, nil)

    @obj.send(:request_validation, http_challenge)

    http_challenge.verify
  end

  test "#prepare_http_challenge stores validation content in Redis" do
    sample_token = "sample_token"
    sample_content = "sample content"
    http_challenge = Object.new
    http_challenge.define_singleton_method(:token) { sample_token }
    http_challenge.define_singleton_method(:file_content) { sample_content }

    captured = nil
    redis = $redis
    original_setex = redis.method(:setex)
    redis.define_singleton_method(:setex) { |*args| captured = args; true }

    begin
      @obj.send(:prepare_http_challenge, http_challenge)
    ensure
      redis.singleton_class.send(:remove_method, :setex) rescue nil
      redis.define_singleton_method(:setex, original_setex)
    end

    assert_equal [RedisKey.acme_challenge(sample_token), SslCertificates::LetsEncrypt::CHALLENGE_TTL, sample_content], captured
  end

  test "#delete_http_challenge removes token from Redis" do
    sample_token = "sample_token"
    http_challenge = Object.new
    http_challenge.define_singleton_method(:token) { sample_token }

    captured = nil
    redis = $redis
    original_del = redis.method(:del)
    redis.define_singleton_method(:del) { |key| captured = key; 1 }

    begin
      @obj.send(:delete_http_challenge, http_challenge)
    ensure
      redis.singleton_class.send(:remove_method, :del) rescue nil
      redis.define_singleton_method(:del, original_del)
    end

    assert_equal RedisKey.acme_challenge(sample_token), captured
  end

  test "#order_certificate returns order and http challenge" do
    http_challenge = Object.new
    authorization = Object.new
    authorization.define_singleton_method(:http) { http_challenge }
    order = Object.new
    order.define_singleton_method(:authorizations) { [authorization] }
    client = Object.new
    client.define_singleton_method(:new_order) { |**| order }

    @obj.define_singleton_method(:client) { client }

    assert_equal [order, http_challenge], @obj.send(:order_certificate)
  end

  test "#client creates ACME account when none exists" do
    client = Object.new
    client.define_singleton_method(:account) { raise Acme::Client::Error::AccountDoesNotExist }
    new_account_calls = 0
    client.define_singleton_method(:new_account) { |**| new_account_calls += 1 }

    @obj.define_singleton_method(:account_private_key) { Object.new }
    original_new = Acme::Client.method(:new)
    Acme::Client.define_singleton_method(:new) { |**| client }

    begin
      result = @obj.send(:client)
    ensure
      Acme::Client.singleton_class.send(:remove_method, :new)
      Acme::Client.define_singleton_method(:new, original_new)
    end

    assert_equal client, result
    assert_equal 1, new_account_calls
  end

  test "#client doesn't create ACME account when one exists" do
    client = Object.new
    client.define_singleton_method(:account) { Object.new }
    new_account_calls = 0
    client.define_singleton_method(:new_account) { |**| new_account_calls += 1 }

    @obj.define_singleton_method(:account_private_key) { Object.new }
    original_new = Acme::Client.method(:new)
    Acme::Client.define_singleton_method(:new) { |**| client }

    begin
      @obj.send(:client)
    ensure
      Acme::Client.singleton_class.send(:remove_method, :new)
      Acme::Client.define_singleton_method(:new, original_new)
    end

    assert_equal 0, new_account_calls
  end

  test "#account_private_key returns RSA key from env" do
    private_key = "private_key"
    pkey_double = Object.new
    original_new = OpenSSL::PKey::RSA.method(:new)
    seen_arg = nil
    OpenSSL::PKey::RSA.define_singleton_method(:new) { |arg| seen_arg = arg; pkey_double }
    ENV["LETS_ENCRYPT_ACCOUNT_PRIVATE_KEY"] = private_key

    begin
      assert_equal pkey_double, @obj.send(:account_private_key)
      assert_equal private_key, seen_arg
    ensure
      OpenSSL::PKey::RSA.singleton_class.send(:remove_method, :new)
      OpenSSL::PKey::RSA.define_singleton_method(:new, original_new)
      ENV["LETS_ENCRYPT_ACCOUNT_PRIVATE_KEY"] = nil
    end
  end

  class ProcessTest < ActiveSupport::TestCase
    CONFIG_FIXTURE = Rails.root.join("spec", "support", "fixtures", "ssl_certificates.yml.erb").to_s

    setup do
      @original_config_file = SslCertificates::Base.const_get(:CONFIG_FILE)
      SslCertificates::Base.send(:remove_const, :CONFIG_FILE)
      SslCertificates::Base.const_set(:CONFIG_FILE, CONFIG_FIXTURE)

      @custom_domain = custom_domains(:ssl_www_example)
      @obj = SslCertificates::LetsEncrypt.new(@custom_domain.domain)

      @order_double = Object.new
      @http_challenge_double = Object.new
      @certificate_double = Object.new
      @sample_token = "challenge-token"

      @http_challenge_double.define_singleton_method(:token) { "challenge-token" }

      cert_key = @obj.send(:certificate_private_key)
      @obj.define_singleton_method(:order_certificate) { [@order_double, @http_challenge_double] }
      @obj.instance_variable_set(:@order_double, @order_double)
      @obj.instance_variable_set(:@http_challenge_double, @http_challenge_double)
      @obj.define_singleton_method(:prepare_http_challenge) { |_| }
      @obj.define_singleton_method(:request_validation) { |_| }
      @obj.define_singleton_method(:poll_validation_status) { |_| }
      @obj.define_singleton_method(:sleep) { |*| }
      @certificate_double_local = @certificate_double
      cert = @certificate_double
      @obj.define_singleton_method(:finalize_with_csr) { |_o, _h| cert }
      @upload_args = []
      ua = @upload_args
      @obj.define_singleton_method(:upload_certificate_to_s3) { |*args| ua << args }

      @redis = $redis
      @original_del = @redis.method(:del)
      @del_args = []
      da = @del_args
      @redis.define_singleton_method(:del) { |k| da << k; 1 }
    end

    teardown do
      SslCertificates::Base.send(:remove_const, :CONFIG_FILE)
      SslCertificates::Base.const_set(:CONFIG_FILE, @original_config_file)
      @redis.singleton_class.send(:remove_method, :del) rescue nil
      @redis.define_singleton_method(:del, @original_del)
    end

    test "processes the LetsEncrypt order" do
      @obj.process

      assert_equal [[@certificate_double, @obj.send(:certificate_private_key)]], @upload_args
    end

    test "deletes the http challenge from Redis on success" do
      @obj.process

      assert_includes @del_args, RedisKey.acme_challenge(@sample_token)
    end

    test "logs message and returns false when order fails" do
      @obj.define_singleton_method(:finalize_with_csr) { |_o, _h| raise "sample error message" }
      log_calls = []
      @obj.define_singleton_method(:log_message) { |dom, msg| log_calls << [dom, msg] }

      assert_equal false, @obj.process
      assert_nil @custom_domain.ssl_certificate_issued_at
      assert_includes log_calls, [@custom_domain.domain, "SSL Certificate cannot be issued. Error: sample error message"]
    end

    test "deletes the http challenge from Redis on failure" do
      @obj.define_singleton_method(:finalize_with_csr) { |_o, _h| raise "x" }
      @obj.define_singleton_method(:log_message) { |*| }

      @obj.process

      assert_includes @del_args, RedisKey.acme_challenge(@sample_token)
    end
  end
end
