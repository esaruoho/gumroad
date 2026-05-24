# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    GithubStarsController.singleton_class.send(:alias_method, :__orig_cached_count, :cached_count) unless GithubStarsController.singleton_class.method_defined?(:__orig_cached_count)
    GithubStarsController.define_singleton_method(:cached_count) { 1234 }
  end

  teardown do
    if GithubStarsController.singleton_class.method_defined?(:__orig_cached_count)
      GithubStarsController.singleton_class.send(:remove_method, :cached_count)
      GithubStarsController.singleton_class.send(:alias_method, :cached_count, :__orig_cached_count)
      GithubStarsController.singleton_class.send(:remove_method, :__orig_cached_count)
    end
  end

  test "GET features_md returns markdown with the feature list" do
    get :features_md
    assert_response :success
    assert_includes @response.content_type, "text/markdown"
    assert_includes @response.body, "# Gumroad features"
    assert_includes @response.body, "Digital products"
    assert_includes @response.body, "Memberships"
    assert_includes @response.body, "REST API"
  end

  test "GET small_bets renders successfully" do
    get :small_bets
    assert_response :success
    assert_equal "Small Bets by Gumroad", @controller.send(:page_title)
    assert_equal true, assigns(:hide_layouts)
  end

  test "GET saas renders successfully" do
    get :saas
    assert_response :success
    assert_includes @controller.send(:page_title), "Gumroad for SaaS"
    assert_equal true, assigns(:hide_layouts)
  end
end
