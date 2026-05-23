# frozen_string_literal: true

require "test_helper"

class SitemapServiceTest < ActiveSupport::TestCase
  setup do
    skip "TODO: migrate spec/services/sitemap_service_spec.rb " \
         "(writes gzipped sitemap files via SitemapGenerator + uses Redis::Namespace " \
         "scoped to robots_redis_namespace + depends on a Link with .preview_url; " \
         "out of scope for the fast Minitest lane)."
  end
end
