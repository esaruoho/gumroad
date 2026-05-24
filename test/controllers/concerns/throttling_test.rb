# frozen_string_literal: true

require "test_helper"

class ThrottlingTestAnonymousController < ApplicationController
  include Throttling

  before_action :test_throttle

  def test_action
    render json: { success: true }
  end

  private
    def test_throttle
      throttle!(key: "test_key", limit: 5, period: 1.hour)
    end
end

class ThrottlingTest < ActionDispatch::IntegrationTest
  setup do
    @redis = $redis
    @redis.del("test_key")

    Rails.application.routes.draw do
      get "test_throttle", to: "throttling_test_anonymous#test_action"
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "allows requests within the limit" do
    get "/test_throttle"
    assert_response :ok
    assert_equal true, JSON.parse(response.body)["success"]
  end

  test "blocks requests when limit is exceeded" do
    5.times do
      get "/test_throttle"
      assert_response :ok
    end

    get "/test_throttle"
    assert_response :too_many_requests
    assert_match(/Rate limit exceeded/, JSON.parse(response.body)["error"])
    assert_predicate response.headers["Retry-After"], :present?
  end

  test "sets expiration on first request" do
    get "/test_throttle"
    ttl = @redis.ttl("test_key")
    assert ttl > 0
    assert ttl <= 3600
  end

  test "does not reset expiration on subsequent requests" do
    get "/test_throttle"
    initial_ttl = @redis.ttl("test_key")

    @redis.expire("test_key", initial_ttl - 1)

    get "/test_throttle"
    second_ttl = @redis.ttl("test_key")

    assert second_ttl < initial_ttl
  end
end
