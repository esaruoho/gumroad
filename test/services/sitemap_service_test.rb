# frozen_string_literal: true

require "test_helper"

class SitemapServiceTest < ActiveSupport::TestCase
  setup do
    @date = Time.current.to_date
    @sitemap_path = Rails.public_path.join("sitemap/products/monthly/#{@date.year}/#{@date.month}/sitemap.xml.gz")
    FileUtils.rm_f(@sitemap_path)
    # Reuse a product whose created_at falls in the current month.
    @product = links(:basic_user_product)
    @product.update_columns(created_at: @date.beginning_of_month + 1.day, updated_at: @date.beginning_of_month + 1.day)
  end

  teardown do
    FileUtils.rm_f(@sitemap_path)
  end

  test "#generate creates the sitemap file" do
    SitemapService.new.generate(@date)
    assert File.exist?(@sitemap_path), "expected #{@sitemap_path} to exist"
  end

  test "#generate clears the /robots.txt sitemap configs cache" do
    redis_ns = Redis::Namespace.new(:robots_redis_namespace, redis: $redis)
    redis_ns.set("sitemap_configs", "[\"https://example.com/robots.txt\"]")
    SitemapService.new.generate(@date)
    assert_nil redis_ns.get("sitemap_configs")
  end
end
