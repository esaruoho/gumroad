# frozen_string_literal: true

require "test_helper"

class ReissueSslCertificateForUpdatedCustomDomainsTest < ActiveSupport::TestCase
  setup do
    @domain = custom_domains(:user_domain_user_only)
    # Mark domain as having previously been issued an SSL certificate
    @domain.update_column(:ssl_certificate_issued_at, 1.day.ago)
  end

  test "generates new certificates when no valid certs exist" do
    reset_called = false
    generate_called = false
    cert_mod = Module.new
    cert_mod.send(:define_method, :reset_ssl_certificate_issued_at!) { reset_called = true }
    cert_mod.send(:define_method, :generate_ssl_certificate) { generate_called = true }
    CustomDomain.prepend(cert_mod)

    ver_mod = Module.new
    ver_mod.send(:define_method, :has_valid_ssl_certificates?) { false }
    CustomDomainVerificationService.prepend(ver_mod)

    ReissueSslCertificateForUpdatedCustomDomains.new.perform

    assert reset_called
    assert generate_called
  ensure
    cert_mod.module_eval { instance_methods(false).each { |m| remove_method(m) } } if cert_mod
    ver_mod.module_eval { instance_methods(false).each { |m| remove_method(m) } } if ver_mod
  end

  test "does not generate new certificates when valid certs exist" do
    reset_called = false
    generate_called = false
    cert_mod = Module.new
    cert_mod.send(:define_method, :reset_ssl_certificate_issued_at!) { reset_called = true }
    cert_mod.send(:define_method, :generate_ssl_certificate) { generate_called = true }
    CustomDomain.prepend(cert_mod)

    ver_mod = Module.new
    ver_mod.send(:define_method, :has_valid_ssl_certificates?) { true }
    CustomDomainVerificationService.prepend(ver_mod)

    ReissueSslCertificateForUpdatedCustomDomains.new.perform

    refute reset_called
    refute generate_called
  ensure
    cert_mod.module_eval { instance_methods(false).each { |m| remove_method(m) } } if cert_mod
    ver_mod.module_eval { instance_methods(false).each { |m| remove_method(m) } } if ver_mod
  end
end
