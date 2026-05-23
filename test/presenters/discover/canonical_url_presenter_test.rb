# frozen_string_literal: true

require "test_helper"

class Discover::CanonicalUrlPresenterTest < ActiveSupport::TestCase
  setup do
    @discover_domain_with_protocol = UrlService.discover_domain_with_protocol
  end

  test "returns the root url when no valid search parameters are present" do
    params = ActionController::Parameters.new({})
    assert_equal "#{@discover_domain_with_protocol}/", Discover::CanonicalUrlPresenter.canonical_url(params)

    params = ActionController::Parameters.new({ sort: "hot_and_new" })
    assert_equal "#{@discover_domain_with_protocol}/", Discover::CanonicalUrlPresenter.canonical_url(params)

    params = ActionController::Parameters.new({ max_price: 0 })
    assert_equal "#{@discover_domain_with_protocol}/", Discover::CanonicalUrlPresenter.canonical_url(params)
  end

  test "returns the url with parameters" do
    params = ActionController::Parameters.new({ query: "product" })
    assert_equal "#{@discover_domain_with_protocol}/?query=product", Discover::CanonicalUrlPresenter.canonical_url(params)

    params = ActionController::Parameters.new({ taxonomy: "3d/3d-modeling" })
    assert_equal "#{@discover_domain_with_protocol}/3d/3d-modeling", Discover::CanonicalUrlPresenter.canonical_url(params)

    params = ActionController::Parameters.new({ taxonomy: "3d/3d-modeling", query: "product" })
    assert_equal "#{@discover_domain_with_protocol}/3d/3d-modeling?query=product", Discover::CanonicalUrlPresenter.canonical_url(params)

    params = ActionController::Parameters.new({ tags: ["3d model"] })
    assert_equal "#{@discover_domain_with_protocol}/?tags=3d+model", Discover::CanonicalUrlPresenter.canonical_url(params)
  end

  test "returns the url with sorted parameters and values" do
    params = ActionController::Parameters.new({ rating: 1, query: "product", sort: "featured" })
    assert_equal "#{@discover_domain_with_protocol}/?query=product&rating=1&sort=featured", Discover::CanonicalUrlPresenter.canonical_url(params)

    params = ActionController::Parameters.new({ max_price: 1, tags: ["tagb", "taga"], sort: "hot_and_new" })
    assert_equal "#{@discover_domain_with_protocol}/?max_price=1&sort=hot_and_new&tags=taga%2Ctagb", Discover::CanonicalUrlPresenter.canonical_url(params)

    params = ActionController::Parameters.new({ max_price: 1, tags: ["taga", "tagb"], sort: "hot_and_new" })
    assert_equal "#{@discover_domain_with_protocol}/?max_price=1&sort=hot_and_new&tags=taga%2Ctagb", Discover::CanonicalUrlPresenter.canonical_url(params)
  end

  test "ignores empty parameters" do
    params = ActionController::Parameters.new({ query: "product", max_price: 0, tags: [], sort: "" })
    assert_equal "#{@discover_domain_with_protocol}/?max_price=0&query=product", Discover::CanonicalUrlPresenter.canonical_url(params)
  end

  test "ignores invalid parameters" do
    params = ActionController::Parameters.new({ query: "product", invalid: "invalid", unknown: "unknown" })
    assert_equal "#{@discover_domain_with_protocol}/?query=product", Discover::CanonicalUrlPresenter.canonical_url(params)
  end

  test "correctly formats array parameters" do
    params = ActionController::Parameters.new({ tags: ["tag1", "tag2"], filetypes: ["mp3", "zip"] })
    assert_equal "#{@discover_domain_with_protocol}/?filetypes=mp3%2Czip&tags=tag1%2Ctag2", Discover::CanonicalUrlPresenter.canonical_url(params)
  end
end
