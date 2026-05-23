# frozen_string_literal: true

require "test_helper"

class HelpCenter::CategoriesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @category = HelpCenter::Category.first
    @request.headers["X-Inertia"] = "true"
  end

  def inertia_page
    JSON.parse(@response.body)
  end

  test "GET show returns successful response with Inertia page data" do
    get :show, params: { slug: @category.slug }
    assert_response :success
    page = inertia_page
    assert_equal "HelpCenter/Categories/Show", page["component"]
    assert_equal @category.title, page["props"]["category"]["title"]
    assert_equal @category.slug, page["props"]["category"]["slug"]
    assert_kind_of Array, page["props"]["category"]["articles"]
  end

  test "GET show includes sidebar categories" do
    get :show, params: { slug: @category.slug }
    page = inertia_page
    assert_kind_of Array, page["props"]["sidebar_categories"]
    first = page["props"]["sidebar_categories"].first
    assert first.key?("title")
    assert first.key?("slug")
    assert first.key?("url")
  end

  test "GET show sets meta tags (HTML response)" do
    @request.env.delete("HTTP_X_INERTIA")
    get :show, params: { slug: @category.slug }
    assert_response :success
    assert_includes @response.body, "#{@category.title} - Gumroad Help Center</title>"
  end

  test "GET show redirects to help center root for non-existent categories" do
    get :show, params: { slug: "non-existent-category" }
    assert_redirected_to help_center_root_path
  end
end
