# frozen_string_literal: true

require "test_helper"

class TipOptionsServiceTest < ActiveSupport::TestCase
  setup do
    $redis.del(RedisKey.tip_options)
    $redis.del(RedisKey.default_tip_option)
  end

  test ".get_tip_options returns the parsed tip options when Redis has valid tip options" do
    $redis.set(RedisKey.tip_options, "[10, 20, 30]")
    assert_equal [10, 20, 30], TipOptionsService.get_tip_options
  end

  test ".get_tip_options returns the default tip options when Redis has invalid JSON" do
    $redis.set(RedisKey.tip_options, "invalid_json")
    assert_equal TipOptionsService::DEFAULT_TIP_OPTIONS, TipOptionsService.get_tip_options
  end

  test ".get_tip_options returns the default tip options when Redis has invalid tip options" do
    $redis.set(RedisKey.tip_options, '[10,"bad",20]')
    assert_equal TipOptionsService::DEFAULT_TIP_OPTIONS, TipOptionsService.get_tip_options
  end

  test ".get_tip_options returns the default tip options when Redis has no tip options" do
    assert_equal TipOptionsService::DEFAULT_TIP_OPTIONS, TipOptionsService.get_tip_options
  end

  test ".set_tip_options sets the tip options in Redis when options are valid" do
    TipOptionsService.set_tip_options([5, 15, 25])
    assert_equal "[5,15,25]", $redis.get(RedisKey.tip_options)
  end

  test ".set_tip_options raises an ArgumentError when options are invalid" do
    error = assert_raises(ArgumentError) { TipOptionsService.set_tip_options("invalid") }
    assert_equal "Tip options must be an array of integers", error.message
  end

  test ".get_default_tip_option returns the default tip option when Redis has a valid default tip option" do
    $redis.set(RedisKey.default_tip_option, "20")
    assert_equal 20, TipOptionsService.get_default_tip_option
  end

  test ".get_default_tip_option returns the default default tip option when Redis has an invalid default tip option" do
    $redis.set(RedisKey.default_tip_option, "invalid")
    assert_equal TipOptionsService::DEFAULT_DEFAULT_TIP_OPTION, TipOptionsService.get_default_tip_option
  end

  test ".get_default_tip_option returns the default default tip option when Redis has no default tip option" do
    assert_equal TipOptionsService::DEFAULT_DEFAULT_TIP_OPTION, TipOptionsService.get_default_tip_option
  end

  test ".set_default_tip_option sets the default tip option in Redis when option is valid" do
    TipOptionsService.set_default_tip_option(10)
    assert_equal "10", $redis.get(RedisKey.default_tip_option)
  end

  test ".set_default_tip_option raises an ArgumentError when option is invalid" do
    error = assert_raises(ArgumentError) { TipOptionsService.set_default_tip_option("invalid") }
    assert_equal "Default tip option must be an integer", error.message
  end
end
