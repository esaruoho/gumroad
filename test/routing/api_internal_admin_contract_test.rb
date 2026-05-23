# frozen_string_literal: true

require "test_helper"

class ApiInternalAdminContractRoutingTest < ActionDispatch::IntegrationTest
  def route_for(path, method)
    Rails.application.routes.recognize_path("https://#{API_DOMAIN}#{path}", method:)
  end

  def assert_route(path, method, **expected)
    actual = route_for(path, method)
    expected.each do |k, v|
      assert_equal v, actual[k], "Expected #{method.to_s.upcase} #{path} #{k.inspect} to be #{v.inspect}, got #{actual[k].inspect}"
    end
  end

  # Contract for gumroad-cli: these are read-only GET routes the CLI depends on.
  # "Safe" here means no server-side state mutation (unlike write/refund/watch endpoints below).
  test "routes the safe read endpoints that gumroad-cli consumes" do
    assert_route "/internal/admin/purchases/123", :get, controller: "api/internal/admin/purchases", action: "show", id: "123"
    assert_route "/internal/admin/purchases/search", :get, controller: "api/internal/admin/purchases", action: "search"
    assert_route "/internal/admin/licenses/lookup", :get, controller: "api/internal/admin/licenses", action: "lookup"
    assert_route "/internal/admin/users/info", :get, controller: "api/internal/admin/users", action: "info"
    assert_route "/internal/admin/users/affiliates", :get, controller: "api/internal/admin/users", action: "affiliates"
    assert_route "/internal/admin/users/comments", :get, controller: "api/internal/admin/users", action: "comments"
    assert_route "/internal/admin/users/compliance_info", :get, controller: "api/internal/admin/users", action: "compliance_info"
    assert_route "/internal/admin/users/purchases", :get, controller: "api/internal/admin/users", action: "purchases"
    assert_route "/internal/admin/users/radar_stats", :get, controller: "api/internal/admin/users", action: "radar_stats"
    assert_route "/internal/admin/users/related", :get, controller: "api/internal/admin/users", action: "related"
    assert_route "/internal/admin/users/suspension", :get, controller: "api/internal/admin/users", action: "suspension"
    assert_route "/internal/admin/payouts", :get, controller: "api/internal/admin/payouts", action: "index"
  end

  test "routes the precise refund endpoint" do
    assert_route "/internal/admin/purchases/123/refund", :post, controller: "api/internal/admin/purchases", action: "refund", id: "123"
  end

  test "routes the user watchlist write endpoints" do
    assert_route "/internal/admin/users/watch", :post, controller: "api/internal/admin/users", action: "watch"
    assert_route "/internal/admin/users/update_watch", :post, controller: "api/internal/admin/users", action: "update_watch"
    assert_route "/internal/admin/users/unwatch", :post, controller: "api/internal/admin/users", action: "unwatch"
  end

  test "routes the products endpoints" do
    assert_route "/internal/admin/products", :get, controller: "api/internal/admin/products", action: "index"
    assert_route "/internal/admin/products/abc123", :get, controller: "api/internal/admin/products", action: "show", id: "abc123"
  end
end
