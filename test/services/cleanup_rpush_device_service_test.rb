# frozen_string_literal: true

require "test_helper"

class CleanupRpushDeviceServiceTest < ActiveSupport::TestCase
  setup do
    @device_a = devices(:cleanup_rpush_device_a)
    @device_b = devices(:cleanup_rpush_device_b)
    @device_c = devices(:cleanup_rpush_device_c)
  end

  test "removes device records for the undeliverable token" do
    destroy_called = false
    feedback = Struct.new(:device_token).new(@device_b.token)
    feedback.define_singleton_method(:destroy) { destroy_called = true }
    feedback.define_singleton_method(:inspect) { "feedback-b" }

    before_count = Device.count
    CleanupRpushDeviceService.new(feedback).process
    assert destroy_called, "expected feedback.destroy to be invoked"
    assert_equal before_count - 1, Device.count
    refute_includes Device.all.ids, @device_b.id
  end

  test "works without any errors" do
    feedback = Struct.new(:device_token).new(@device_b.token)
    feedback.define_singleton_method(:destroy) { true }
    feedback.define_singleton_method(:inspect) { "feedback-b" }

    assert_nothing_raised do
      CleanupRpushDeviceService.new(feedback).process
    end
  end
end
