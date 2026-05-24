# frozen_string_literal: true

require "test_helper"

class BlackFridayStatsServiceTest < ActiveSupport::TestCase
  setup { Rails.cache.clear }
  teardown { Rails.cache.clear }

  test ".calculate_stats returns placeholder values with zero counts" do
    stats = BlackFridayStatsService.calculate_stats
    assert_equal 0, stats[:active_deals_count]
    assert_equal 0, stats[:revenue_cents]
    assert_equal 0, stats[:average_discount_percentage]
  end

  test ".fetch_stats caches stats; second call does not recalculate" do
    calls = 0
    orig = BlackFridayStatsService.method(:calculate_stats)
    BlackFridayStatsService.define_singleton_method(:calculate_stats) do
      calls += 1
      orig.call
    end
    begin
      a = BlackFridayStatsService.fetch_stats
      b = BlackFridayStatsService.fetch_stats
      assert_equal a, b
      assert_equal 1, calls
    ensure
      BlackFridayStatsService.define_singleton_method(:calculate_stats, orig)
    end
  end

  test ".fetch_stats stores result in Rails cache under correct key" do
    BlackFridayStatsService.fetch_stats
    cached = Rails.cache.read("black_friday_stats")
    assert cached.present?
    assert_equal 0, cached[:active_deals_count]
  end

  test ".fetch_stats recalculates after cache expires" do
    travel_to Time.current do
      BlackFridayStatsService.fetch_stats
      travel 11.minutes
      calls = 0
      orig = BlackFridayStatsService.method(:calculate_stats)
      BlackFridayStatsService.define_singleton_method(:calculate_stats) do
        calls += 1
        orig.call
      end
      begin
        BlackFridayStatsService.fetch_stats
        assert_equal 1, calls
      ensure
        BlackFridayStatsService.define_singleton_method(:calculate_stats, orig)
      end
    end
  end

  test ".fetch_stats recalculates after cache deletion" do
    BlackFridayStatsService.fetch_stats
    Rails.cache.delete("black_friday_stats")
    calls = 0
    orig = BlackFridayStatsService.method(:calculate_stats)
    BlackFridayStatsService.define_singleton_method(:calculate_stats) do
      calls += 1
      orig.call
    end
    begin
      BlackFridayStatsService.fetch_stats
      assert_equal 1, calls
    ensure
      BlackFridayStatsService.define_singleton_method(:calculate_stats, orig)
    end
  end
end
