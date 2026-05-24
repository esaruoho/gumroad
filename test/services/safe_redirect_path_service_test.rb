# frozen_string_literal: true

require "test_helper"

class SafeRedirectPathServiceTest < ActiveSupport::TestCase
  setup do
    @request = OpenStruct.new(host: "test.gumroad.com")
  end

  test "subdomain host: when allowed, returns path" do
    with_const(:ROOT_DOMAIN, "test.gumroad.com") do
      path = "https://username.test.gumroad.com:31337/123"
      assert_equal path, SafeRedirectPathService.new(path, @request).process
    end
  end

  test "subdomain host: when not allowed, returns relative path" do
    with_const(:ROOT_DOMAIN, "test.gumroad.com") do
      path = "https://username.test.gumroad.com:31337/123"
      assert_equal "/123", SafeRedirectPathService.new(path, @request, allow_subdomain_host: false).process
    end
  end

  test "when hosts of request and path are same, returns path" do
    request = OpenStruct.new(host: "test2.gumroad.com")
    path = "https://test2.gumroad.com/123"
    assert_equal path, SafeRedirectPathService.new(path, request).process
  end

  test "when path is a relative path, returns path" do
    assert_equal "/test3", SafeRedirectPathService.new("/test3", @request).process
  end

  test "when safety conditions aren't met, returns parsed path" do
    assert_equal "/test?a=b", SafeRedirectPathService.new("http://example.com/test?a=b", @request).process
  end

  test "escaped external url: clears the parsed path" do
    assert_equal "/evil.org", SafeRedirectPathService.new("////evil.org", @request).process
  end

  test "escaped external url: decodes the parsed path" do
    assert_equal "/evil.org", SafeRedirectPathService.new("///%2Fevil.org", @request).process
  end

  test "does not match malicious domains that try to exploit unescaped dots" do
    with_const(:ROOT_DOMAIN, "gumroad.com") do
      assert_equal "/malicious", SafeRedirectPathService.new("https://attacker.gumroadXcom/malicious", @request).process
    end
  end

  test "correctly matches legitimate subdomains" do
    with_const(:ROOT_DOMAIN, "gumroad.com") do
      path = "https://user.gumroad.com/legitimate"
      assert_equal path, SafeRedirectPathService.new(path, @request).process
    end
  end

  test "when there is only a query parameter, does not prepend forward slash" do
    assert_equal "?query=param", SafeRedirectPathService.new("?query=param", @request).process
  end

  test "when path is nil, raises TypeError" do
    assert_raises(TypeError) { SafeRedirectPathService.new(nil, @request).process }
  end

  test "when path is empty string, raises URI::InvalidURIError" do
    assert_raises(URI::InvalidURIError) { SafeRedirectPathService.new("", @request).process }
  end
end
