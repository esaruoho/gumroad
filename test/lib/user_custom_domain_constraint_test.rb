# frozen_string_literal: true

require "test_helper"

class UserCustomDomainConstraintTest < ActiveSupport::TestCase
  Request = Struct.new(:host, :fullpath, :subdomains, keyword_init: true)

  test "returns false for plain gumroad.com (no subdomain, no custom domain)" do
    req = Request.new(host: "gumroad.com", fullpath: "/", subdomains: [])
    assert_equal false, UserCustomDomainConstraint.matches?(req)
  end

  test "returns true for a subdomain that resolves to a user" do
    # named_seller has username "seller"
    with_const(:ROOT_DOMAIN, "gumroad.com") do
      req = Request.new(host: "seller.gumroad.com", fullpath: "/", subdomains: ["seller"])
      assert_equal true, UserCustomDomainConstraint.matches?(req)
    end
  end

  test "returns true for a custom-domain host that maps to a user with a username" do
    # another-domain.example.com belongs to another_seller (username 'anotherseller')
    req = Request.new(host: "another-domain.example.com", fullpath: "/", subdomains: [])
    assert_equal true, UserCustomDomainConstraint.matches?(req)
  end

  test "returns true when the host is configured to redirect" do
    redirector = SubdomainRedirectorService.new
    SubdomainRedirectorService.stub(:new, redirector) do
      redirector.stub(:redirect_url_for, "https://example.com") do
        req = Request.new(host: "live.gumroad.com", fullpath: "/", subdomains: ["live"])
        assert_equal true, UserCustomDomainConstraint.matches?(req)
      end
    end
  end
end
