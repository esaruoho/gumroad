# frozen_string_literal: true

require "test_helper"

class SslCertificates::RenewTest < ActiveSupport::TestCase
  CONFIG_FIXTURE = Rails.root.join("spec", "support", "fixtures", "ssl_certificates.yml.erb").to_s

  setup do
    @original_config_file = SslCertificates::Base.const_get(:CONFIG_FILE)
    SslCertificates::Base.send(:remove_const, :CONFIG_FILE)
    SslCertificates::Base.const_set(:CONFIG_FILE, CONFIG_FIXTURE)
    @obj = SslCertificates::Renew.new
  end

  teardown do
    SslCertificates::Base.send(:remove_const, :CONFIG_FILE)
    SslCertificates::Base.const_set(:CONFIG_FILE, @original_config_file)
  end

  test "inherits from SslCertificates::Base" do
    assert_operator SslCertificates::Renew, :<, SslCertificates::Base
  end

  test "#process invokes generate_ssl_certificate on each candidate domain" do
    custom_domain = custom_domains(:user_domain_user_only)
    expected_renew_in = @obj.send(:renew_in)
    seen_duration = nil

    relation_double = Object.new
    relation_double.define_singleton_method(:certificate_absent_or_older_than) do |duration|
      seen_duration = duration
      [custom_domain]
    end

    original_alive = CustomDomain.singleton_class.instance_method(:alive)
    CustomDomain.define_singleton_method(:alive) { relation_double }

    generate_called = 0
    custom_domain.define_singleton_method(:generate_ssl_certificate) { generate_called += 1 }

    begin
      @obj.process
    ensure
      CustomDomain.singleton_class.send(:remove_method, :alive)
      CustomDomain.singleton_class.send(:define_method, :alive, original_alive)
    end

    assert_equal expected_renew_in, seen_duration
    assert_equal 1, generate_called
  end
end
