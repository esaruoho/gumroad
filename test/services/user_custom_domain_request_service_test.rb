# frozen_string_literal: true

require "test_helper"

class UserCustomDomainRequestServiceTest < ActiveSupport::TestCase
  def stub_host(host)
    Object.new.tap { |o| o.define_singleton_method(:host) { host } }
  end

  test "returns false when request is from Gumroad domain" do
    refute UserCustomDomainRequestService.valid?(stub_host("app.test.gumroad.com"))
  end

  test "returns false when request is from Discover domain" do
    refute UserCustomDomainRequestService.valid?(stub_host("test.gumroad.com"))
  end

  test "returns true when request is from a custom domain" do
    assert UserCustomDomainRequestService.valid?(stub_host("example.com"))
  end

  test "returns true when request is from Gumroad subdomain" do
    assert UserCustomDomainRequestService.valid?(stub_host("example.test.gumroad.com"))
  end

  test "returns false when request is a product custom domain" do
    # product_domain fixture has domain "with-product.example.com" + product_id set
    refute UserCustomDomainRequestService.valid?(stub_host("with-product.example.com"))
  end

  test "returns false when request is a product custom domain with a www prefix" do
    # product_domain_apex has the apex form so the www-prefix lookup branch finds it.
    refute UserCustomDomainRequestService.valid?(stub_host("www.with-product.com"))
  end
end
