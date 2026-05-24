# frozen_string_literal: true

require "test_helper"

class HelpCenterPresenterTest < ActiveSupport::TestCase
  def view_context
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create
    controller.request.host = DOMAIN
    controller.view_context
  end

  def presenter
    @presenter ||= HelpCenterPresenter.new(view_context:)
  end

  test "#index_props returns categories with articles" do
    props = presenter.index_props
    assert_kind_of Array, props[:categories]
    refute_empty props[:categories]
    first = props[:categories].first
    [:title, :url, :audience, :articles].each { |k| assert first.key?(k), "missing #{k}" }
  end

  test "#article_props returns article data with category and content" do
    article = HelpCenter::Article.first
    props = presenter.article_props(article)
    assert_equal article.title, props[:article][:title]
    assert_equal article.slug, props[:article][:slug]
    assert_kind_of String, props[:article][:content]
    refute_empty props[:article][:content]
    [:title, :slug, :url].each { |k| assert props[:article][:category].key?(k) }
  end

  test "#article_props returns sidebar categories" do
    article = HelpCenter::Article.first
    props = presenter.article_props(article)
    assert_kind_of Array, props[:sidebar_categories]
    first = props[:sidebar_categories].first
    [:title, :slug, :url].each { |k| assert first.key?(k) }
  end

  test "#category_props returns category data with articles" do
    category = HelpCenter::Category.first
    props = presenter.category_props(category)
    assert_equal category.title, props[:category][:title]
    assert_equal category.slug, props[:category][:slug]
    assert_kind_of Array, props[:category][:articles]
  end

  test "#category_props returns sidebar categories" do
    category = HelpCenter::Category.first
    props = presenter.category_props(category)
    assert_kind_of Array, props[:sidebar_categories]
    first = props[:sidebar_categories].first
    [:title, :slug, :url].each { |k| assert first.key?(k) }
  end
end
