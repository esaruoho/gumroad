# frozen_string_literal: true

require "test_helper"

class AnonymousCursorPaginatedTestController < ActionController::Base
  include Api::Internal::Admin::CursorPaginated

  def index
    render json: { limit: cursor_limit }
  end

  def invalid
    raise Api::Internal::Admin::CursorPagination::InvalidCursor
  end

  def mismatched
    paginate_with_cursor(Payment.all, order: [[:created_at, :desc], [:id, :desc]])
    render json: { success: true }
  end
end

class Api::Internal::Admin::CursorPaginatedTest < ActionController::TestCase
  tests AnonymousCursorPaginatedTestController

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get :index, to: "anonymous_cursor_paginated_test#index"
      get :invalid, to: "anonymous_cursor_paginated_test#invalid"
      get :mismatched, to: "anonymous_cursor_paginated_test#mismatched"
    end
  end

  test "returns a bad request response for invalid cursors" do
    get :invalid
    assert_response :bad_request
    assert_equal({ "success" => false, "message" => "invalid cursor" }, JSON.parse(response.body))
  end

  test "returns a bad request response when a signed cursor has the wrong sort keys" do
    cursor = Api::Internal::Admin::CursorPagination.encode("id" => 1)
    get :mismatched, params: { cursor: }
    assert_response :bad_request
    assert_equal({ "success" => false, "message" => "invalid cursor" }, JSON.parse(response.body))
  end

  test "uses the default limit when the limit parameter is missing" do
    get :index
    assert_equal Api::Internal::Admin::CursorPaginated::DEFAULT_LIMIT, JSON.parse(response.body)["limit"]
  end

  test "uses the requested limit when it is in range" do
    get :index, params: { limit: 37 }
    assert_equal 37, JSON.parse(response.body)["limit"]
  end

  test "caps the requested limit at the maximum" do
    get :index, params: { limit: 10_000 }
    assert_equal Api::Internal::Admin::CursorPaginated::MAX_LIMIT, JSON.parse(response.body)["limit"]
  end

  test "uses the default limit when the requested limit is non-positive or non-numeric" do
    ["0", "-5", "abc", "2abc", ""].each do |limit|
      get :index, params: { limit: }
      assert_equal Api::Internal::Admin::CursorPaginated::DEFAULT_LIMIT,
                   JSON.parse(response.body)["limit"],
                   "limit=#{limit.inspect}"
    end
  end
end
