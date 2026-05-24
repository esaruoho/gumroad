# frozen_string_literal: true

require "test_helper"

class Api::Internal::HomePageNumbersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "returns the cached result as JSON" do
    cached_value = { prev_week_payout_usd: "$37,537" }
    Rails.cache.write("homepage_numbers", cached_value)
    begin
      get :index
      assert_response :success
      assert_equal cached_value.as_json, JSON.parse(@response.body)
    ensure
      Rails.cache.delete("homepage_numbers")
    end
  end

  test "fetches the values from HomePagePresenter when not cached" do
    Rails.cache.delete("homepage_numbers")
    $redis.set(RedisKey.prev_week_payout_usd, "37437")
    expected_value = { prev_week_payout_usd: "$37,437" }
    get :index
    assert_response :success
    assert_equal expected_value.as_json, JSON.parse(@response.body)
  end
end
