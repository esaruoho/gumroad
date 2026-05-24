# frozen_string_literal: true

require "test_helper"

class BlockedObjectTest < ActiveSupport::TestCase
  setup do
    BlockedObject.delete_all
  end

  teardown do
    BlockedObject.delete_all
  end

  test ".block! when blocked object doesn't exist creates a new blocked object record" do
    count = BlockedObject.count
    BlockedObject.block!(BLOCKED_OBJECT_TYPES[:ip_address], "123.456.789.0", nil, expires_in: 1.hour)
    assert_equal count + 1, BlockedObject.all.count
    assert_equal true, BlockedObject.find_by(object_value: "123.456.789.0").blocked?
  end

  test ".block! when blocked object exists updates the existing record" do
    BlockedObject.block!(BLOCKED_OBJECT_TYPES[:ip_address], "789.123.456.0", nil, expires_in: 1.hour)
    BlockedObject.unblock!("789.123.456.0")
    count = BlockedObject.count
    BlockedObject.block!(BLOCKED_OBJECT_TYPES[:ip_address], "789.123.456.0", nil, expires_in: 1.hour)
    assert_equal count, BlockedObject.count
  end

  test ".block! when :expires_in is present blocks and sets the expiration date appropriately" do
    count = BlockedObject.active.count
    BlockedObject.block!(BLOCKED_OBJECT_TYPES[:ip_address], "789.124.456.0", nil, expires_in: 3.days)
    assert_equal count + 1, BlockedObject.active.count
    assert_not_nil BlockedObject.last.expires_at
  end

  test ".block! when :expires_in is present, is not active after the expiration date" do
    count = BlockedObject.active.count
    BlockedObject.block!(BLOCKED_OBJECT_TYPES[:ip_address], "789.125.456.0", nil, expires_in: -3.days)
    assert_equal count, BlockedObject.active.count
  end

  test "#unblock! unblocks the blocked object" do
    ip_address = "157.45.09.212"
    BlockedObject.block!(BLOCKED_OBJECT_TYPES[:ip_address], ip_address, nil, expires_in: 1.hour)
    blocked_object = BlockedObject.find_by(object_value: ip_address)

    assert_equal true, blocked_object.blocked?
    blocked_object.unblock!
    assert_equal false, blocked_object.blocked?
  end

  test ".unblock! when it isn't there fails silently" do
    assert_nil BlockedObject.find_by(object_value: "lol")
    assert_nothing_raised { BlockedObject.unblock!("lol") }
  end

  test ".unblock! when it is there unblocks" do
    BlockedObject.block!(BLOCKED_OBJECT_TYPES[:ip_address], "456.789.123.0", nil, expires_in: 1.hour)
    assert_equal true, BlockedObject.find_by(object_value: "456.789.123.0").blocked?
    BlockedObject.unblock!("456.789.123.0")
    assert_equal false, BlockedObject.find_by(object_value: "456.789.123.0").blocked?
  end

  test ".charge_processor_fingerprint returns the list of blocked objects with that object_type" do
    email = "paypal@example.com"
    BlockedObject.block!(BLOCKED_OBJECT_TYPES[:email], email, nil)
    BlockedObject.block!(BLOCKED_OBJECT_TYPES[:charge_processor_fingerprint], email, nil)

    assert_equal 1, BlockedObject.charge_processor_fingerprint.count
    blocked_object = BlockedObject.charge_processor_fingerprint.first
    assert_equal BLOCKED_OBJECT_TYPES[:charge_processor_fingerprint], blocked_object.object_type
    assert_equal email, blocked_object.object_value
  end

  test "expires_at validation: ip_address with blocked_at is invalid without expires_at" do
    blocked_object = BlockedObject.new(
      object_type: BLOCKED_OBJECT_TYPES[:ip_address],
      object_value: "192.168.1.1",
      blocked_at: Time.current
    )
    assert_not blocked_object.valid?
    assert_includes blocked_object.errors[:expires_at], "can't be blank"
  end

  test "expires_at validation: ip_address with blocked_at is valid with expires_at" do
    blocked_object = BlockedObject.new(
      object_type: BLOCKED_OBJECT_TYPES[:ip_address],
      object_value: "192.168.1.1",
      blocked_at: Time.current,
      expires_at: Time.current + 1.hour
    )
    assert blocked_object.valid?
  end

  test "expires_at validation: ip_address with nil blocked_at is valid without expires_at" do
    blocked_object = BlockedObject.new(
      object_type: BLOCKED_OBJECT_TYPES[:ip_address],
      object_value: "192.168.1.1",
      blocked_at: nil,
      expires_at: nil
    )
    assert blocked_object.valid?
  end

  test "expires_at validation: ip_address with nil blocked_at is valid with expires_at" do
    blocked_object = BlockedObject.new(
      object_type: BLOCKED_OBJECT_TYPES[:ip_address],
      object_value: "192.168.1.1",
      blocked_at: nil,
      expires_at: Time.current + 1.hour
    )
    assert blocked_object.valid?
  end

  test "expires_at validation: non-ip_address with blocked_at is valid without expires_at" do
    blocked_object = BlockedObject.new(
      object_type: BLOCKED_OBJECT_TYPES[:email],
      object_value: "test@example.com",
      blocked_at: Time.current,
      expires_at: nil
    )
    assert blocked_object.valid?
  end

  test "expires_at validation: non-ip_address with blocked_at is valid with expires_at" do
    blocked_object = BlockedObject.new(
      object_type: BLOCKED_OBJECT_TYPES[:email],
      object_value: "test@example.com",
      blocked_at: Time.current,
      expires_at: Time.current + 1.hour
    )
    assert blocked_object.valid?
  end

  test "expires_at validation: non-ip_address with nil blocked_at is valid without expires_at" do
    blocked_object = BlockedObject.new(
      object_type: BLOCKED_OBJECT_TYPES[:email],
      object_value: "test@example.com",
      blocked_at: nil,
      expires_at: nil
    )
    assert blocked_object.valid?
  end
end
