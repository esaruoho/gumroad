# frozen_string_literal: true

require "test_helper"

class HelpCenter::ArticlesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @article = HelpCenter::Article.first
    @request.headers["X-Inertia"] = "true"
  end

  def inertia_page
    JSON.parse(@response.body)
  end

  test "GET index returns successful response with Inertia page data" do
    get :index
    assert_response :success
    page = inertia_page
    assert_equal "HelpCenter/Articles/Index", page["component"]
    categories = page["props"]["categories"]
    assert_kind_of Array, categories
    refute_empty categories
    first = categories.first
    %w[title url audience articles].each { |k| assert first.key?(k), "missing #{k}" }
  end

  test "GET index includes all categories with their articles" do
    get :index
    categories = inertia_page["props"]["categories"]
    titles = categories.map { |c| c["title"] }
    assert_includes titles, "Accessing your purchase"
    assert_includes titles, "Before you buy"
    assert_includes titles, "Open an account"

    category_with_articles = categories.find { |c| c["articles"].present? }
    refute_nil category_with_articles
    article = category_with_articles["articles"].first
    assert article.key?("title")
    assert article.key?("url")
  end

  test "GET index sets meta tags (HTML response)" do
    @request.env.delete("HTTP_X_INERTIA")
    get :index
    assert_response :success
    assert_includes @response.body, "Gumroad Help Center</title>"
  end

  test "GET show returns successful response with Inertia page data" do
    get :show, params: { slug: @article.slug }
    assert_response :success
    page = inertia_page
    assert_equal "HelpCenter/Articles/Show", page["component"]
    article = page["props"]["article"]
    assert_equal @article.title, article["title"]
    assert_equal @article.slug, article["slug"]
    category = article["category"]
    %w[title slug url].each { |k| assert category.key?(k), "missing #{k}" }
  end

  test "GET show includes sidebar categories" do
    get :show, params: { slug: @article.slug }
    cats = inertia_page["props"]["sidebar_categories"]
    assert_kind_of Array, cats
    first = cats.first
    %w[title slug url].each { |k| assert first.key?(k) }
  end

  test "GET show sets meta tags (HTML response)" do
    @request.env.delete("HTTP_X_INERTIA")
    get :show, params: { slug: @article.slug }
    assert_includes @response.body, "#{CGI.escapeHTML(@article.title)} - Gumroad Help Center</title>"
  end

  test "GET show sets description meta tags from the article (HTML response)" do
    @request.env.delete("HTTP_X_INERTIA")
    get :show, params: { slug: @article.slug }
    html = Nokogiri::HTML.parse(@response.body)
    assert_equal @article.description, html.xpath("//meta[@name='description']/@content").text
    assert_equal @article.description, html.xpath("//meta[@property='og:description']/@value").text
    assert_equal @article.description, html.xpath("//meta[@name='twitter:description']/@content").text
  end

  test "GET show redirects to help center root for non-existent articles" do
    get :show, params: { slug: "non-existent-article" }
    assert_redirected_to help_center_root_path
  end

  test "GET show legacy article redirect" do
    get :show, params: { slug: "284-jobs-at-gumroad" }
    assert_redirected_to "/about#jobs"
    assert_response :moved_permanently
  end
end
