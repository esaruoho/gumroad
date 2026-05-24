# frozen_string_literal: true

require "test_helper"

class ProductsHelper::OfferCodesTest < ActionView::TestCase
  tests ProductsHelper
  include Rails.application.routes.url_helpers

  setup do
    @creator = users(:named_seller)
    @product = links(:named_seller_product)
  end

  test "BLACKFRIDAY2025: on user's domain — adds code parameter to URL" do
    request = ActionDispatch::Request.new(
      "HTTP_HOST" => "seller.test.gumroad.com:1234",
      "SERVER_PORT" => "1234",
      "rack.url_scheme" => "http"
    )
    stub_user_by_domain("seller.test.gumroad.com", @creator)

    url = url_for_product_page(@product, request: request, offer_code: "BLACKFRIDAY2025")
    assert_includes url, "code=BLACKFRIDAY2025"
  end

  test "BLACKFRIDAY2025: on user's domain — includes other parameters along with code" do
    request = ActionDispatch::Request.new(
      "HTTP_HOST" => "seller.test.gumroad.com:1234",
      "SERVER_PORT" => "1234",
      "rack.url_scheme" => "http"
    )
    stub_user_by_domain("seller.test.gumroad.com", @creator)

    url = url_for_product_page(
      @product,
      request: request,
      offer_code: "BLACKFRIDAY2025",
      recommended_by: "discover",
      query: "search term"
    )

    assert_includes url, "code=BLACKFRIDAY2025"
    assert_includes url, "recommended_by=discover"
    assert_includes url, "query=search+term"
  end

  test "BLACKFRIDAY2025: not on user's domain — adds code parameter to URL" do
    request = ActionDispatch::Request.new(
      "HTTP_HOST" => "test.gumroad.com:1234",
      "SERVER_PORT" => "1234",
      "rack.url_scheme" => "http"
    )
    stub_user_by_domain("test.gumroad.com", nil)

    url = url_for_product_page(@product, request: request, offer_code: "BLACKFRIDAY2025")
    assert_includes url, "code=BLACKFRIDAY2025"
  end

  test "BLACKFRIDAY2025: not on user's domain — includes other parameters except query" do
    request = ActionDispatch::Request.new(
      "HTTP_HOST" => "test.gumroad.com:1234",
      "SERVER_PORT" => "1234",
      "rack.url_scheme" => "http"
    )
    stub_user_by_domain("test.gumroad.com", nil)

    url = url_for_product_page(
      @product,
      request: request,
      offer_code: "BLACKFRIDAY2025",
      recommended_by: "discover",
      query: "search term"
    )

    assert_includes url, "code=BLACKFRIDAY2025"
    assert_includes url, "recommended_by=discover"
    refute_includes url, "query="
  end

  test "nil offer_code — does not add code parameter to URL" do
    request = ActionDispatch::Request.new(
      "HTTP_HOST" => "test.gumroad.com:1234",
      "SERVER_PORT" => "1234",
      "rack.url_scheme" => "http"
    )
    stub_user_by_domain("test.gumroad.com", nil)

    url = url_for_product_page(@product, request: request, offer_code: nil)
    refute_includes url, "code="
  end

  test "empty offer_code — does not add code parameter to URL" do
    request = ActionDispatch::Request.new(
      "HTTP_HOST" => "test.gumroad.com:1234",
      "SERVER_PORT" => "1234",
      "rack.url_scheme" => "http"
    )
    stub_user_by_domain("test.gumroad.com", nil)

    url = url_for_product_page(@product, request: request, offer_code: "")
    refute_includes url, "code="
  end

  private
    # Stub user_by_domain on the test instance (helper module is mixed into
    # ActionView::TestCase). The original lives in CustomDomainConfig.
    def stub_user_by_domain(host, user)
      define_singleton_method(:user_by_domain) do |h|
        h == host ? user : nil
      end
    end
end
