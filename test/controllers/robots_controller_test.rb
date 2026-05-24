# frozen_string_literal: true

require "test_helper"

class RobotsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @sitemap_config = "Sitemap: https://example.com/sitemap.xml"
    @user_agent_rules = ["User-agent: *", "Disallow: /purchases/"]

    @robots_service = Minitest::Mock.new
    def @robots_service.sitemap_configs; ["Sitemap: https://example.com/sitemap.xml"]; end
    def @robots_service.user_agent_rules; ["User-agent: *", "Disallow: /purchases/"]; end

    RobotsService.define_singleton_method(:__orig_new, RobotsService.method(:new)) unless RobotsService.respond_to?(:__orig_new)
    stub = @robots_service
    RobotsService.define_singleton_method(:new) { |*_a, **_kw| stub }
  end

  teardown do
    if RobotsService.respond_to?(:__orig_new)
      RobotsService.singleton_class.send(:remove_method, :new)
      RobotsService.define_singleton_method(:new, RobotsService.method(:__orig_new))
      RobotsService.singleton_class.send(:remove_method, :__orig_new)
    end
  end

  test "renders robots.txt" do
    get :index, format: :txt

    assert_response :success
    assert_includes @response.body, @sitemap_config
  end

  test "includes user agent rules" do
    get :index, format: :txt

    assert_response :success
    @user_agent_rules.each do |rule|
      assert_includes @response.body, rule
    end
  end
end
