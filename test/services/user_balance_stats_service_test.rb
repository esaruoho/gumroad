# frozen_string_literal: true

require "test_helper"

class UserBalanceStatsServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
    @service = UserBalanceStatsService.new(user: @user)
    @example_values = {
      foo: "bar",
      nested: { key1: { key2: "value2" } },
      records: [{ id: 1, name: "first" }, { id: 2, name: "second" }]
    }

    $redis.del(@service.send(:cache_key))
    $redis.del(RedisKey.balance_stats_sales_caching_threshold)
    $redis.del(RedisKey.balance_stats_users_excluded_from_caching)
    UpdateUserBalanceStatsCacheWorker.jobs.clear
  end

  test "generate returns the expected payload shape and timestamp" do
    now = Time.zone.local(2020, 1, 1)

    travel_to(now) do
      @service.stub(:payout_period_data, {}) do
        @user.stub(:sales_cents_total, ->(*_args, **_kwargs) { 0 }) do

          generated = @service.send(:generate)

          assert_instance_of Hash, generated
          assert_equal(
            [:generated_at, :is_paginating, :next_payout_period_data, :overview, :payments, :payout_period_data, :processing_payout_periods_data].sort,
            generated.keys.sort
          )
          assert_equal now, generated[:generated_at]
        end
      end
    end
  end

  test "fetch returns cached value and enqueues cache refresh when cache is enabled" do
    $redis.setex(@service.send(:cache_key), 48.hours.to_i, @example_values.to_json)

    @service.stub(:should_use_cache?, true) do
      @service.stub(:generate, -> { flunk "generate should not be called for a cache hit" }) do
        assert_equal @example_values, @service.fetch
      end
    end

    assert_equal 1, UpdateUserBalanceStatsCacheWorker.jobs.size
    assert_equal [@user.id], UpdateUserBalanceStatsCacheWorker.jobs.last["args"]
  end

  test "fetch generates value on cache miss when cache is enabled" do
    @service.stub(:should_use_cache?, true) do
      @service.stub(:generate, @example_values) do
        assert_equal @example_values, @service.fetch
      end
    end
    assert_equal 1, UpdateUserBalanceStatsCacheWorker.jobs.size
  end

  test "fetch generates value without enqueueing when cache is disabled" do
    @service.stub(:should_use_cache?, false) do
      @service.stub(:generate, @example_values) do
        assert_equal @example_values, @service.fetch
      end
    end
    assert_empty UpdateUserBalanceStatsCacheWorker.jobs
  end

  test "write_cache writes generated values and read_cache reads them back" do
    assert_nil @service.send(:read_cache)

    @service.stub(:generate, @example_values) do
      @service.write_cache
    end

    assert_equal @example_values, @service.send(:read_cache)
  end

  test "read_cache returns nil for malformed cached JSON" do
    $redis.setex(@service.send(:cache_key), 48.hours.to_i, "{not-json")

    assert_nil @service.send(:read_cache)
  end

  test "should_use_cache is false below the large-seller threshold" do
    large_sellers(:large_seller_two).update_columns(user_id: @user.id, sales_count: 50)

    stub_const(UserBalanceStatsService, :DEFAULT_SALES_CACHING_THRESHOLD, 100) do
      assert_equal false, @service.send(:should_use_cache?)
    end
  end

  test "should_use_cache is true at or above the large-seller threshold" do
    large_sellers(:large_seller_two).update_columns(user_id: @user.id, sales_count: 200)

    stub_const(UserBalanceStatsService, :DEFAULT_SALES_CACHING_THRESHOLD, 100) do
      assert_equal true, @service.send(:should_use_cache?)
    end
  end

  test "cacheable_users honors default threshold redis override and exclusions" do
    basic_user = users(:basic_user)
    large_sellers(:large_seller_one).update_columns(user_id: basic_user.id, sales_count: 100)
    large_sellers(:large_seller_two).update_columns(user_id: @user.id, sales_count: 200)

    stub_const(UserBalanceStatsService, :DEFAULT_SALES_CACHING_THRESHOLD, 150) do
      assert_equal [@user], UserBalanceStatsService.cacheable_users.to_a

      $redis.set(RedisKey.balance_stats_sales_caching_threshold, 100)
      assert_equal [basic_user, @user].sort_by(&:id), UserBalanceStatsService.cacheable_users.to_a.sort_by(&:id)

      $redis.sadd(RedisKey.balance_stats_users_excluded_from_caching, [@user.id])
      assert_equal [basic_user], UserBalanceStatsService.cacheable_users.to_a
    end
  end
end
