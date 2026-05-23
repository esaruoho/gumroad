# frozen_string_literal: true

require "test_helper"

class SslCertificates::GenerateTest < ActiveSupport::TestCase
  CONFIG_FIXTURE = Rails.root.join("spec", "support", "fixtures", "ssl_certificates.yml.erb").to_s

  setup do
    @original_config_file = SslCertificates::Base.const_get(:CONFIG_FILE)
    SslCertificates::Base.send(:remove_const, :CONFIG_FILE)
    SslCertificates::Base.const_set(:CONFIG_FILE, CONFIG_FIXTURE)

    @custom_domain = custom_domains(:ssl_www_example)
    @obj = SslCertificates::Generate.new(@custom_domain)
  end

  teardown do
    SslCertificates::Base.send(:remove_const, :CONFIG_FILE)
    SslCertificates::Base.const_set(:CONFIG_FILE, @original_config_file)
  end

  test "inherits from SslCertificates::Base" do
    assert_operator SslCertificates::Generate, :<, SslCertificates::Base
  end

  test "#hourly_rate_limit_reached? returns false when below limit" do
    @obj.define_singleton_method(:rate_limit) { 1 }
    custom_domains(:ssl_example_1).set_ssl_certificate_issued_at!

    assert_equal false, @obj.send(:hourly_rate_limit_reached?)
  end

  test "#hourly_rate_limit_reached? returns true when at limit" do
    @obj.define_singleton_method(:rate_limit) { 1 }
    custom_domains(:ssl_example_1).set_ssl_certificate_issued_at!
    custom_domains(:ssl_example_2).set_ssl_certificate_issued_at!

    assert_equal true, @obj.send(:hourly_rate_limit_reached?)
  end

  test "#hourly_rate_limit_reached? counts deleted domains" do
    @obj.define_singleton_method(:rate_limit) { 1 }
    custom_domains(:ssl_example_1).set_ssl_certificate_issued_at!
    custom_domains(:ssl_example_2).set_ssl_certificate_issued_at!
    deleted = custom_domains(:ssl_example_3)
    deleted.set_ssl_certificate_issued_at!
    deleted.mark_deleted!

    assert_equal true, @obj.send(:hourly_rate_limit_reached?)
  end

  test "#can_order_certificates? returns false when domain has a valid certificate" do
    @custom_domain.set_ssl_certificate_issued_at!
    assert_equal [false, "Has valid certificate"], @obj.send(:can_order_certificates?)
  end

  test "#can_order_certificates? returns false when domain is invalid" do
    @custom_domain.domain = "test_store.example.com"
    @custom_domain.save(validate: false)

    assert_equal [false, "Invalid domain"], @obj.send(:can_order_certificates?)
  end

  test "#can_order_certificates? returns false when hourly limit is reached" do
    relation = Object.new
    rate_limit_plus_one = @obj.send(:rate_limit) + 1
    relation.define_singleton_method(:count) { rate_limit_plus_one }

    original = CustomDomain.singleton_class.instance_method(:certificates_younger_than)
    seen = nil
    CustomDomain.define_singleton_method(:certificates_younger_than) { |dur| seen = dur; relation }

    begin
      assert_equal [false, "Hourly limit reached"], @obj.send(:can_order_certificates?)
      assert_equal @obj.send(:rate_limit_hours), seen
    ensure
      CustomDomain.singleton_class.send(:remove_method, :certificates_younger_than)
      CustomDomain.singleton_class.send(:define_method, :certificates_younger_than, original)
    end
  end

  test "#can_order_certificates? returns false when no domain points to Gumroad" do
    CustomDomain.class_eval do
      define_method(:cname_is_setup_correctly?) { false }
      define_method(:alias_is_setup_correctly?) { false }
    end

    begin
      assert_equal [false, "No domains pointed to Gumroad"], @obj.send(:can_order_certificates?)
    ensure
      CustomDomain.send(:remove_method, :cname_is_setup_correctly?) rescue nil
      CustomDomain.send(:remove_method, :alias_is_setup_correctly?) rescue nil
    end
  end

  test "#domain_check_cache_key formats correctly" do
    assert_equal "domain_check_www.example.com", @obj.send(:domain_check_cache_key)
  end

  test "#generate_certificate invokes LetsEncrypt#process" do
    letsencrypt = Minitest::Mock.new
    letsencrypt.expect(:process, nil)

    original = SslCertificates::LetsEncrypt.method(:new)
    SslCertificates::LetsEncrypt.define_singleton_method(:new) do |dom|
      dom == "test-domain" ? letsencrypt : original.call(dom)
    end

    begin
      @obj.send(:generate_certificate, "test-domain")
    ensure
      SslCertificates::LetsEncrypt.singleton_class.send(:remove_method, :new)
      SslCertificates::LetsEncrypt.define_singleton_method(:new, original)
    end

    letsencrypt.verify
  end

  test "#process logs message when can_order_certificates? returns false" do
    @obj.define_singleton_method(:can_order_certificates?) { [false, "sample error message"] }
    log_calls = []
    @obj.define_singleton_method(:log_message) { |dom, msg| log_calls << [dom, msg] }

    @obj.process

    assert_equal [[@custom_domain.domain, "sample error message"]], log_calls
  end

  test "#process sets ssl_certificate_issued_at and logs success" do
    domains = ["example.com", "www.example.com"]
    @obj.define_singleton_method(:can_order_certificates?) { true }
    CustomDomainVerificationService.class_eval do
      define_method(:domains_pointed_to_gumroad) { domains }
    end

    generate_calls = []
    @obj.define_singleton_method(:generate_certificate) { |d| generate_calls << d; true }
    log_calls = []
    @obj.define_singleton_method(:log_message) { |d, m| log_calls << [d, m] }

    time = Time.current
    begin
      travel_to(time) { @obj.process }
    ensure
      CustomDomainVerificationService.send(:remove_method, :domains_pointed_to_gumroad) rescue nil
    end

    assert_equal domains, generate_calls
    assert_equal time.to_i, @custom_domain.reload.ssl_certificate_issued_at.to_i
    assert_equal domains.map { |d| [d, "Issued SSL certificate."] }, log_calls
  end

  test "#process writes failure to cache and resets ssl_certificate_issued_at" do
    @obj.define_singleton_method(:can_order_certificates?) { true }
    @obj.define_singleton_method(:generate_certificate) { |_| false }
    @custom_domain_local = @custom_domain
    domain = @custom_domain.domain
    CustomDomainVerificationService.class_eval do
      define_method(:domains_pointed_to_gumroad) { [domain] }
    end

    @custom_domain.set_ssl_certificate_issued_at!

    cache = Object.new
    cache_writes = []
    cache.define_singleton_method(:write) { |*args, **kwargs| cache_writes << [args, kwargs]; true }
    original_cache = Rails.method(:cache)
    Rails.define_singleton_method(:cache) { cache }

    log_calls = []
    @obj.define_singleton_method(:log_message) { |d, m| log_calls << [d, m] }

    begin
      @obj.process
    ensure
      Rails.singleton_class.send(:remove_method, :cache)
      Rails.define_singleton_method(:cache, original_cache)
      CustomDomainVerificationService.send(:remove_method, :domains_pointed_to_gumroad) rescue nil
    end

    assert_equal [[["domain_check_#{@custom_domain.domain}", false], { expires_in: @obj.send(:invalid_domain_cache_expires_in) }]], cache_writes
    assert_includes log_calls, [@custom_domain.domain, "LetsEncrypt order failed. Next retry in about 8 hours."]
    assert_nil @custom_domain.reload.ssl_certificate_issued_at
  end
end
