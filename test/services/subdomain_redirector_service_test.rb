# frozen_string_literal: true

require "test_helper"

class SubdomainRedirectorServiceTest < ActiveSupport::TestCase
  setup do
    @service = SubdomainRedirectorService.new
  end

  def with_protected_hosts(value)
    old = SubdomainRedirectorService.send(:remove_const, :PROTECTED_HOSTS)
    SubdomainRedirectorService.const_set(:PROTECTED_HOSTS, value)
    yield
  ensure
    SubdomainRedirectorService.send(:remove_const, :PROTECTED_HOSTS) if SubdomainRedirectorService.const_defined?(:PROTECTED_HOSTS, false)
    SubdomainRedirectorService.const_set(:PROTECTED_HOSTS, old) if old
  end

  test "#update sets the config in redis" do
    config = "live.gumroad.com=example.com\ntwitter.gumroad.com=twitter.com/gumroad"
    @service.update(config)

    redis_namespace = Redis::Namespace.new(:subdomain_redirect_namespace, redis: $redis)
    assert_equal config, redis_namespace.get("subdomain_redirects_config")
  end

  test "#redirect_url_for finds the correct redirect_url when path is empty" do
    @service.update("live.gumroad.com=example.com\ntwitter.gumroad.com/123=twitter.com/gumroad")
    request = Minitest::Mock.new
    def request.host; "live.gumroad.com"; end
    def request.fullpath; "/"; end

    assert_equal "example.com", @service.redirect_url_for(request)
  end

  test "#redirect_url_for finds the correct redirect_url when path is not empty" do
    @service.update("live.gumroad.com=example.com\ntwitter.gumroad.com/123=twitter.com/gumroad")
    request = Object.new
    def request.host; "twitter.gumroad.com"; end
    def request.fullpath; "/123"; end

    assert_equal "twitter.com/gumroad", @service.redirect_url_for(request)
  end

  test "#redirects returns a hash of hosts and redirect locations" do
    @service.update("live.gumroad.com=example.com\ntwitter.gumroad.com=twitter.com/gumroad")
    assert_equal({ "live.gumroad.com" => "example.com", "twitter.gumroad.com" => "twitter.com/gumroad" }, @service.redirects)
  end

  test "#redirects strips host and location" do
    @service.update("live.gumroad.com   = example.com")
    assert_equal({ "live.gumroad.com" => "example.com" }, @service.redirects)
  end

  test "#redirects splits the config line correctly" do
    @service.update("live.gumroad.com=https://gumroad.com/test?hello=world")
    assert_equal({ "live.gumroad.com" => "https://gumroad.com/test?hello=world" }, @service.redirects)
  end

  test "#redirects ignores invalid config lines" do
    @service.update("abcd\nlive.gumroad.com=example.com")
    assert_equal({ "live.gumroad.com" => "example.com" }, @service.redirects)
  end

  test "#redirects ignores protected domains" do
    with_protected_hosts(["example.com"]) do
      @service.update("example.com=gumroad.com\ntwitter.gumroad.com=twitter.com/gumroad")
      assert_equal({ "twitter.gumroad.com" => "twitter.com/gumroad" }, @service.redirects)
    end
  end

  test "#redirect_config_as_text returns redirect config as text after skipping protected domains" do
    with_protected_hosts(["example.com"]) do
      @service.update("example.com=gumroad.com\ntwitter.gumroad.com=twitter.com/gumroad")
      assert_equal "twitter.gumroad.com=twitter.com/gumroad", @service.redirect_config_as_text
    end
  end
end
