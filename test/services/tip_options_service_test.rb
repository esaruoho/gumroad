# frozen_string_literal: true

require "test_helper"

class TipOptionsServiceTest < ActiveSupport::TestCase
  setup do
    $redis.del(RedisKey.tip_options)
    $redis.del(RedisKey.default_tip_option)
  end

  teardown do
    $redis.del(RedisKey.tip_options)
    $redis.del(RedisKey.default_tip_option)
  end

  # .get_tip_options
  test ".get_tip_options returns parsed options when Redis has valid tip options" do
    $redis.set(RedisKey.tip_options, "[10, 20, 30]")
    assert_equal [10, 20, 30], TipOptionsService.get_tip_options
  end

  test ".get_tip_options returns default when Redis has invalid JSON" do
    $redis.set(RedisKey.tip_options, "invalid_json")
    assert_equal TipOptionsService::DEFAULT_TIP_OPTIONS, TipOptionsService.get_tip_options
  end

  test ".get_tip_options returns default when Redis has invalid tip options" do
    $redis.set(RedisKey.tip_options, '[10,"bad",20]')
    assert_equal TipOptionsService::DEFAULT_TIP_OPTIONS, TipOptionsService.get_tip_options
  end

  test ".get_tip_options returns default when Redis has no tip options" do
    assert_equal TipOptionsService::DEFAULT_TIP_OPTIONS, TipOptionsService.get_tip_options
  end

  # .set_tip_options
  test ".set_tip_options stores tip options in Redis when valid" do
    TipOptionsService.set_tip_options([5, 15, 25])
    assert_equal "[5,15,25]", $redis.get(RedisKey.tip_options)
  end

  test ".set_tip_options raises ArgumentError when options are invalid" do
    error = assert_raises(ArgumentError) { TipOptionsService.set_tip_options("invalid") }
    assert_equal "Tip options must be an array of integers", error.message
  end

  # .get_default_tip_option
  test ".get_default_tip_option returns the default tip option when Redis has a valid value" do
    $redis.set(RedisKey.default_tip_option, "20")
    assert_equal 20, TipOptionsService.get_default_tip_option
  end

  test ".get_default_tip_option returns the default when Redis has an invalid value" do
    $redis.set(RedisKey.default_tip_option, "invalid")
    assert_equal TipOptionsService::DEFAULT_DEFAULT_TIP_OPTION, TipOptionsService.get_default_tip_option
  end

  test ".get_default_tip_option returns the default when Redis has no value" do
    assert_equal TipOptionsService::DEFAULT_DEFAULT_TIP_OPTION, TipOptionsService.get_default_tip_option
  end

  # .set_default_tip_option
  test ".set_default_tip_option sets the default tip option in Redis when valid" do
    TipOptionsService.set_default_tip_option(10)
    assert_equal "10", $redis.get(RedisKey.default_tip_option)
  end

  test ".set_default_tip_option raises ArgumentError when invalid" do
    error = assert_raises(ArgumentError) { TipOptionsService.set_default_tip_option("invalid") }
    assert_equal "Default tip option must be an integer", error.message
  end
end
