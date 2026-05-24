# frozen_string_literal: true

require "test_helper"

class RobotsServiceTest < ActiveSupport::TestCase
  setup do
    @redis_namespace = Redis::Namespace.new(:robots_redis_namespace, redis: $redis)
    @redis_namespace.del("sitemap_configs")
    @sitemap_config = "Sitemap: #{PUBLIC_STORAGE_CDN_S3_PROXY_HOST}/products/sitemap.xml"
    @user_agent_rules = ["User-agent: *", "Disallow: /purchases/"]
  end

  teardown do
    @redis_namespace.del("sitemap_configs")
  end

  test "#sitemap_configs generates sitemap configs and caches them" do
    response = Struct.new(:contents).new([OpenStruct.new(key: "products/sitemap.xml")])
    s3 = Object.new
    s3.define_singleton_method(:list_objects) { |**_kwargs| [response] }

    Aws::S3::Client.stub(:new, s3) do
      assert_equal [@sitemap_config], RobotsService.new.sitemap_configs
    end
    assert_equal [@sitemap_config].to_json, @redis_namespace.get("sitemap_configs")
  end

  test "#sitemap_configs doesn't regenerate when cache exists" do
    call_count = 0
    original = RobotsService.instance_method(:generate_sitemap_configs)
    RobotsService.send(:define_method, :generate_sitemap_configs) do
      call_count += 1
      ["Sitemap: example"]
    end

    begin
      2.times { RobotsService.new.sitemap_configs }
      assert_equal 1, call_count
    ensure
      RobotsService.send(:define_method, :generate_sitemap_configs, original)
    end
  end

  test "#user_agent_rules returns the user agent rules" do
    assert_equal @user_agent_rules, RobotsService.new.user_agent_rules
  end

  test "#expire_sitemap_configs_cache deletes the sitemap_configs cache key" do
    @redis_namespace.set("sitemap_configs", @sitemap_config)
    RobotsService.new.expire_sitemap_configs_cache
    assert_nil @redis_namespace.get("sitemap_configs")
  end
end
