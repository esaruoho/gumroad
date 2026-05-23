# frozen_string_literal: true

require "test_helper"

class CareersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    unless GithubStarsController.singleton_class.method_defined?(:__orig_cached_count)
      GithubStarsController.singleton_class.send(:alias_method, :__orig_cached_count, :cached_count)
    end
    GithubStarsController.define_singleton_method(:cached_count) { 1234 }
  end

  teardown do
    if GithubStarsController.singleton_class.method_defined?(:__orig_cached_count)
      GithubStarsController.singleton_class.send(:remove_method, :cached_count)
      GithubStarsController.singleton_class.send(:alias_method, :cached_count, :__orig_cached_count)
      GithubStarsController.singleton_class.send(:remove_method, :__orig_cached_count)
    end
  end

  # GET index

  test "GET index renders successfully when career_pages feature is active" do
    Feature.activate(:career_pages)
    begin
      get :index
      assert_response :success
      assert_equal "Careers at Gumroad - Build the road with us", assigns(:title)
      assert_equal true, assigns(:hide_layouts)
      assert_equal JOBS, assigns(:jobs)
    ensure
      Feature.deactivate(:career_pages)
    end
  end

  test "GET index returns 404 when career_pages feature is inactive" do
    Feature.deactivate(:career_pages)
    assert_raises(ActionController::RoutingError) { get :index }
  end

  # GET show

  test "GET show renders successfully for a valid job slug" do
    Feature.activate(:career_pages)
    begin
      get :show, params: { slug: "design-engineer" }
      assert_response :success
      assert_equal "design-engineer", assigns(:job)[:slug]
      assert_equal "Design Engineer", assigns(:job)[:title]
      assert_equal "Design Engineer - Gumroad Careers", assigns(:title)
      assert_equal true, assigns(:hide_layouts)
    ensure
      Feature.deactivate(:career_pages)
    end
  end

  test "GET show raises not found for an invalid job slug" do
    Feature.activate(:career_pages)
    begin
      assert_raises(ActionController::RoutingError) { get :show, params: { slug: "invalid-job-slug" } }
    ensure
      Feature.deactivate(:career_pages)
    end
  end

  test "GET show returns 404 when career_pages feature is inactive" do
    Feature.deactivate(:career_pages)
    assert_raises(ActionController::RoutingError) { get :show, params: { slug: "design-engineer" } }
  end
end
