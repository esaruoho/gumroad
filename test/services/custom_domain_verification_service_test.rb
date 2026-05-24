# frozen_string_literal: true

require "test_helper"

class CustomDomainVerificationServiceTest < ActiveSupport::TestCase
  # A minimal stand-in for Resolv::DNS that returns canned answers.
  class FakeResolver
    attr_accessor :timeouts

    def initialize(lookup_table)
      @lookup_table = lookup_table
    end

    def getresources(domain, type)
      (@lookup_table[[domain, type]] || []).dup
    end
  end

  CnameRecord = Struct.new(:name)
  ARecord     = Struct.new(:address)

  def stub_resolver(lookup_table)
    fake = FakeResolver.new(lookup_table)
    Resolv::DNS.stub(:new, fake) { yield }
  end

  test "process returns true when CNAME points to CUSTOM_DOMAIN_CNAME" do
    domain = "store.example.com"
    lookup = {
      [domain, Resolv::DNS::Resource::IN::CNAME] => [CnameRecord.new(CUSTOM_DOMAIN_CNAME)],
    }
    stub_resolver(lookup) do
      assert_equal true, CustomDomainVerificationService.new(domain: domain).process
    end
  end

  test "process returns true when ALIAS A records match CUSTOM_DOMAIN_CNAME addresses" do
    domain = "store.example.com"
    lookup = {
      [domain, Resolv::DNS::Resource::IN::CNAME] => [CnameRecord.new("wrong-domain.gumroad.com")],
      [CUSTOM_DOMAIN_CNAME, Resolv::DNS::Resource::IN::A] => [ARecord.new("100.0.0.1"), ARecord.new("100.0.0.2")],
      [CUSTOM_DOMAIN_STATIC_IP_HOST, Resolv::DNS::Resource::IN::A] => [ARecord.new("100.0.0.10"), ARecord.new("100.0.0.20")],
      [domain, Resolv::DNS::Resource::IN::A] => [ARecord.new("100.0.0.1"), ARecord.new("100.0.0.2")],
    }
    stub_resolver(lookup) do
      assert_equal true, CustomDomainVerificationService.new(domain: domain).process
    end
  end

  test "process returns true when ALIAS A records match CUSTOM_DOMAIN_STATIC_IP_HOST addresses" do
    domain = "store.example.com"
    lookup = {
      [domain, Resolv::DNS::Resource::IN::CNAME] => [CnameRecord.new("wrong-domain.gumroad.com")],
      [CUSTOM_DOMAIN_CNAME, Resolv::DNS::Resource::IN::A] => [ARecord.new("100.0.0.1"), ARecord.new("100.0.0.2")],
      [CUSTOM_DOMAIN_STATIC_IP_HOST, Resolv::DNS::Resource::IN::A] => [ARecord.new("100.0.0.10"), ARecord.new("100.0.0.20")],
      [domain, Resolv::DNS::Resource::IN::A] => [ARecord.new("100.0.0.20"), ARecord.new("100.0.0.10")],
    }
    stub_resolver(lookup) do
      assert_equal true, CustomDomainVerificationService.new(domain: domain).process
    end
  end

  test "process returns false when ALIAS A records do not match either target" do
    domain = "store.example.com"
    lookup = {
      [domain, Resolv::DNS::Resource::IN::CNAME] => [CnameRecord.new("wrong-domain.gumroad.com")],
      [CUSTOM_DOMAIN_CNAME, Resolv::DNS::Resource::IN::A] => [ARecord.new("100.0.0.1"), ARecord.new("100.0.0.2")],
      [CUSTOM_DOMAIN_STATIC_IP_HOST, Resolv::DNS::Resource::IN::A] => [ARecord.new("100.0.0.10"), ARecord.new("100.0.0.20")],
      [domain, Resolv::DNS::Resource::IN::A] => [ARecord.new("100.0.0.2")],
    }
    stub_resolver(lookup) do
      assert_equal false, CustomDomainVerificationService.new(domain: domain).process
    end
  end

  test "process returns false for invalid domains" do
    # No DNS lookups should happen; PublicSuffix.parse raises and rescue returns false.
    stub_resolver({}) do
      assert_equal false, CustomDomainVerificationService.new(domain: "http://example.com").process
    end
  end

  test "domains_pointed_to_gumroad returns root + www for root domain" do
    domain = "example.com"
    lookup = Hash.new { |h, k| h[k] = [CnameRecord.new(CUSTOM_DOMAIN_CNAME)] }
    stub_resolver(lookup) do
      assert_equal ["example.com", "www.example.com"],
                   CustomDomainVerificationService.new(domain: domain).domains_pointed_to_gumroad
    end
  end

  test "domains_pointed_to_gumroad returns only the subdomain when one is supplied" do
    domain = "test.example.com"
    lookup = Hash.new { |h, k| h[k] = [CnameRecord.new(CUSTOM_DOMAIN_CNAME)] }
    stub_resolver(lookup) do
      assert_equal ["test.example.com"],
                   CustomDomainVerificationService.new(domain: domain).domains_pointed_to_gumroad
    end
  end

  test "has_valid_ssl_certificates? returns true and caches result when certs are valid" do
    domain = "example.com"
    lookup = Hash.new { |h, k| h[k] = [CnameRecord.new(CUSTOM_DOMAIN_CNAME)] }

    ssl_service = Object.new
    ssl_service.define_singleton_method(:ssl_file_path) { |_d, _ext| "path/cert" }
    SslCertificates::Base.stub(:new, ssl_service) do
      cert_body = Object.new
      cert_body.define_singleton_method(:read) { "cert-bytes" }
      cert_response = Struct.new(:body).new(cert_body)
      cert_obj = Object.new
      cert_obj.define_singleton_method(:exists?) { true }
      cert_obj.define_singleton_method(:get) { cert_response }
      bucket = Object.new
      bucket.define_singleton_method(:object) { |_key| cert_obj }
      s3 = Object.new
      s3.define_singleton_method(:bucket) { |_name| bucket }

      Aws::InstanceProfileCredentials.stub(:new, Object.new) do
      Aws::S3::Resource.stub(:new, ->(*_a, **_o) { s3 }) do
        fake_cert = Struct.new(:not_after).new(5.days.from_now)
        OpenSSL::X509::Certificate.stub(:new, fake_cert) do
          # Ensure no stale cache entries from a prior run.
          ns = Redis::Namespace.new(:ssl_cert_check_namespace, redis: $redis)
          ns.del("ssl_cert_check:example.com")
          ns.del("ssl_cert_check:www.example.com")

          stub_resolver(lookup) do
            assert_equal true, CustomDomainVerificationService.new(domain: domain).has_valid_ssl_certificates?
          end

          assert_equal "true", ns.get("ssl_cert_check:example.com")
          assert_equal "true", ns.get("ssl_cert_check:www.example.com")

          ns.del("ssl_cert_check:example.com")
          ns.del("ssl_cert_check:www.example.com")
        end
      end
      end
    end
  end
end
