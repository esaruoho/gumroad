# frozen_string_literal: true

require "test_helper"

class UnblockObjectWorkerTest < ActiveSupport::TestCase
  test "unblocks email domains" do
    email_domain = "example.com"
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email_domain], object_value: email_domain)
    assert_equal 1, PlatformBlock.active.email_domain.count

    UnblockObjectWorker.new.perform(email_domain)
    assert_equal 0, PlatformBlock.active.email_domain.count
  end

  test "unblocks every row sharing the object_value across types" do
    value = "shared@example.com"
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: value)
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:charge_processor_fingerprint], object_value: value)
    assert_equal 2, PlatformBlock.active.where(object_value: value).count

    UnblockObjectWorker.new.perform(value)

    assert_empty PlatformBlock.active.where(object_value: value)
  end
end
