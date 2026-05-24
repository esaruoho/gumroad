# frozen_string_literal: true

require "test_helper"

class BlockObjectWorkerTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin_user)
  end

  test "blocks email domain without expiration" do
    assert_equal 0, PlatformBlock.email_domain.count

    BlockObjectWorker.new.perform("email_domain", "example.com", @admin.id)

    assert_equal 1, PlatformBlock.email_domain.count
    blocked = PlatformBlock.active.find_by(object_value: "example.com")
    assert_equal "example.com", blocked.object_value
    assert_equal @admin.id, blocked.blocked_by
    assert_nil blocked.expires_at
  end

  test "blocks IP address with expiration" do
    assert_equal 0, PlatformBlock.ip_address.count

    BlockObjectWorker.new.perform("ip_address", "172.0.0.1", @admin.id, PlatformBlock::IP_ADDRESS_BLOCKING_DURATION_IN_MONTHS.months.to_i)

    assert_equal 1, PlatformBlock.ip_address.count
    blocked = PlatformBlock.active.find_by(object_value: "172.0.0.1")
    assert_equal "172.0.0.1", blocked.object_value
    assert_equal @admin.id, blocked.blocked_by
    assert_not_nil blocked.expires_at
  end
end
