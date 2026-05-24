# frozen_string_literal: true

require "test_helper"

class PlatformBlockTest < ActiveSupport::TestCase
  test ".add! creates a new row" do
    assert_difference -> { PlatformBlock.count }, 1 do
      PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: "fraud@example.com", by: 1)
    end

    record = PlatformBlock.find_by(object_value: "fraud@example.com")
    assert_equal PlatformBlock::TYPES[:email], record.object_type
    assert_equal 1, record.blocked_by
    assert_in_delta Time.current, record.blocked_at, 60
    assert_nil record.expires_at
  end

  test ".add! sets expires_at from expires_in" do
    record = PlatformBlock.add!(object_type: PlatformBlock::TYPES[:ip_address], object_value: "157.45.9.212", expires_in: 1.hour)
    assert_in_delta 1.hour.from_now, record.expires_at, 60
  end

  test ".add! refreshes an existing row instead of inserting a second one" do
    first = PlatformBlock.add!(object_type: PlatformBlock::TYPES[:ip_address], object_value: "1.2.3.4", expires_in: 1.hour)
    assert_no_difference -> { PlatformBlock.count } do
      second = PlatformBlock.add!(object_type: PlatformBlock::TYPES[:ip_address], object_value: "1.2.3.4", expires_in: 6.hours)
      assert_equal first.id, second.id
    end
    assert_in_delta 6.hours.from_now, first.reload.expires_at, 60
  end

  test ".add! returns the hydrated record" do
    record = PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: "x@example.com")
    assert_kind_of PlatformBlock, record
    assert record.persisted?
    assert_equal "x@example.com", record.object_value
  end

  test "#unblock! nulls blocked_at and expires_at without removing the row" do
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:ip_address], object_value: "157.45.09.212", expires_in: 1.hour)
    record = PlatformBlock.find_by(object_value: "157.45.09.212")
    assert record.blocked_at.present?

    record.unblock!

    assert PlatformBlock.find_by(object_value: "157.45.09.212").present?
    assert_nil record.reload.blocked_at
    assert_nil record.expires_at
    assert_empty PlatformBlock.active.where(object_value: "157.45.09.212")
  end

  test "#unblock! lets a subsequent add! reuse the existing row" do
    first = PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: "reblock@example.com")
    first.unblock!

    second = PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: "reblock@example.com")
    assert_equal first.id, second.id
    assert second.blocked_at.present?
  end

  test "expiration: is not active after the expiration date" do
    count = PlatformBlock.active.count
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:ip_address], object_value: "789.125.456.0", expires_in: -3.days)
    assert_equal count, PlatformBlock.active.count
  end

  test "expiration: is active before the expiration date" do
    count = PlatformBlock.active.count
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:ip_address], object_value: "789.124.456.0", expires_in: 3.days)
    assert_equal count + 1, PlatformBlock.active.count
  end

  test "scopes per object type: filters by charge_processor_fingerprint type" do
    email = "paypal@example.com"
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: email)
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:charge_processor_fingerprint], object_value: email)

    assert_equal 1, PlatformBlock.charge_processor_fingerprint.count

    record = PlatformBlock.charge_processor_fingerprint.first
    assert_equal PlatformBlock::TYPES[:charge_processor_fingerprint], record.object_type
    assert_equal email, record.object_value
  end

  test "add! ip_address raises ArgumentError when expires_in is missing" do
    error = assert_raises(ArgumentError) do
      PlatformBlock.add!(object_type: PlatformBlock::TYPES[:ip_address], object_value: "192.168.1.1")
    end
    assert_match(/expires_in is required/, error.message)
  end

  test "add! ip_address succeeds when expires_in is provided" do
    record = PlatformBlock.add!(object_type: PlatformBlock::TYPES[:ip_address], object_value: "192.168.1.1", expires_in: 1.hour)
    assert record.expires_at.present?
  end

  test "add! allows other types without expires_in" do
    assert_nothing_raised do
      PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: "foo@example.com")
    end
  end

  test "object_type validation rejects unknown object types" do
    record = PlatformBlock.new(object_type: "not_a_real_type", object_value: "x")
    assert_not record.valid?
    assert record.errors[:object_type].present?
  end
end
