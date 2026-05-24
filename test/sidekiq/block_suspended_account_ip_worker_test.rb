# frozen_string_literal: true

require "test_helper"

class BlockSuspendedAccountIpWorkerTest < ActiveSupport::TestCase
  test "adds the seller's ip to the PlatformBlock table if last_sign_in_ip is present" do
    user = users(:suspended_ip_user_one)
    BlockSuspendedAccountIpWorker.new.perform(user.id)

    blocked = PlatformBlock.find_by(object_value: user.last_sign_in_ip)
    assert_not_nil blocked
    assert_equal(
      blocked.blocked_at + PlatformBlock::IP_ADDRESS_BLOCKING_DURATION_IN_MONTHS.months,
      blocked.expires_at
    )
  end

  test "does nothing if last_sign_in_ip is not present" do
    no_ip = users(:suspended_ip_user_no_ip)
    BlockSuspendedAccountIpWorker.new.perform(no_ip.id)

    assert_nil PlatformBlock.find_by(object_value: no_ip.last_sign_in_ip)
  end

  test "does nothing if there is a compliant user with same last_sign_in_ip" do
    user = users(:suspended_ip_user_one)
    other = users(:suspended_ip_user_two)
    other.mark_compliant!(author_name: "ContentModeration")

    BlockSuspendedAccountIpWorker.new.perform(user.id)

    assert_nil PlatformBlock.find_by(object_value: user.last_sign_in_ip)
  end
end
