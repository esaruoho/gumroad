# frozen_string_literal: true

require "test_helper"

class BlockedCustomerObjectTest < ActiveSupport::TestCase
  def build_object(**overrides)
    BlockedCustomerObject.new(
      {
        seller: users(:named_seller),
        object_type: nil,
        object_value: nil,
      }.merge(overrides)
    )
  end

  test "validates presence of seller" do
    obj = build_object
    obj.seller = nil
    refute obj.valid?
    assert_includes obj.errors.full_messages, "Seller must exist"
  end

  test "validates presence of object_type" do
    obj = build_object
    refute obj.valid?
    assert_includes obj.errors.full_messages, "Object type can't be blank"
  end

  test "validates presence of object_value" do
    obj = build_object
    refute obj.valid?
    assert_includes obj.errors.full_messages, "Object value can't be blank"
  end

  test "doesn't allow an unsupported object_type" do
    obj = build_object(object_type: "something")
    refute obj.valid?
    assert_includes obj.errors.full_messages, "Object type is not included in the list"
  end

  test "doesn't allow object_value with invalid email if object_type is email" do
    obj = build_object(object_type: "email", object_value: "invalid-email")
    refute obj.valid?
    assert_includes obj.errors.full_messages, "Object value is invalid"
  end

  test ".email returns records matching object_type 'email'" do
    seller = users(:named_seller)
    blocked1 = BlockedCustomerObject.create!(seller:, object_type: "email", object_value: "john@example.com", blocked_at: DateTime.current)
    blocked2 = BlockedCustomerObject.create!(seller:, object_type: "email", object_value: "alice@example.com")

    assert_equal 2, BlockedCustomerObject.email.count
    assert_equal [blocked1, blocked2].sort, BlockedCustomerObject.email.to_a.sort
  end

  test ".active returns records having non-nil blocked_at" do
    seller = users(:named_seller)
    blocked = BlockedCustomerObject.create!(seller:, object_type: "email", object_value: "john@example.com", blocked_at: DateTime.current)
    BlockedCustomerObject.create!(seller:, object_type: "email", object_value: "alice@example.com")

    assert_equal [blocked], BlockedCustomerObject.active.to_a
  end

  test ".inactive returns records having nil blocked_at" do
    seller = users(:named_seller)
    BlockedCustomerObject.create!(seller:, object_type: "email", object_value: "john@example.com", blocked_at: DateTime.current)
    inactive = BlockedCustomerObject.create!(seller:, object_type: "email", object_value: "alice@example.com")

    assert_equal [inactive], BlockedCustomerObject.inactive.to_a
  end

  test ".email_blocked? returns true when the email is blocked by the seller" do
    seller = users(:named_seller)
    BlockedCustomerObject.block_email!(email: "customer@example.com", seller_id: seller.id)

    assert BlockedCustomerObject.email_blocked?(email: "cuST.omer+test1234@example.com", seller_id: seller.id)
  end

  test ".email_blocked? returns false when the email is not blocked by the seller" do
    seller = users(:named_seller)
    another_seller = users(:another_seller)
    BlockedCustomerObject.block_email!(email: "customer@example.com", seller_id: another_seller.id)
    BlockedCustomerObject.block_email!(email: "another-customer@example.com", seller_id: seller.id)
    BlockedCustomerObject.block_email!(email: "customer@example.com", seller_id: seller.id)
    seller.blocked_customer_objects.active.email.find_by(object_value: "customer@example.com").unblock!

    refute BlockedCustomerObject.email_blocked?(email: "customer@example.com", seller_id: seller.id)
  end

  test ".block_email! blocks an email when not previously blocked" do
    seller = users(:named_seller)
    assert_equal 0, seller.blocked_customer_objects.active.email.count

    assert_difference -> { BlockedCustomerObject.count }, 1 do
      BlockedCustomerObject.block_email!(email: "john@example.com", seller_id: seller.id)
    end

    assert_equal ["john@example.com"], seller.blocked_customer_objects.active.email.pluck(:object_value)
  end

  test ".block_email! does nothing when the email is already blocked" do
    seller = users(:named_seller)
    blocked = BlockedCustomerObject.create!(seller:, object_type: "email", object_value: "john@example.com", blocked_at: 5.minutes.ago)

    assert_no_difference -> { BlockedCustomerObject.count } do
      BlockedCustomerObject.block_email!(email: "john@example.com", seller_id: seller.id)
    end

    assert_equal [blocked], seller.blocked_customer_objects.active.email.to_a
  end

  test ".block_email! re-blocks when the email is unblocked" do
    seller = users(:named_seller)
    blocked = BlockedCustomerObject.create!(seller:, object_type: "email", object_value: "john@example.com")

    freeze_time do
      assert_no_difference -> { BlockedCustomerObject.count } do
        BlockedCustomerObject.block_email!(email: "john@example.com", seller_id: seller.id)
      end
      assert_equal DateTime.current, blocked.reload.blocked_at
    end
  end

  test "#unblock! unblocks the object" do
    seller = users(:named_seller)
    blocked = BlockedCustomerObject.create!(seller:, object_type: "email", object_value: "john@example.com", blocked_at: DateTime.parse("January 1, 2023"))
    blocked.unblock!
    assert_nil blocked.reload.blocked_at
  end

  test "#unblock! does nothing if the object is already unblocked" do
    seller = users(:named_seller)
    blocked = BlockedCustomerObject.create!(seller:, object_type: "email", object_value: "john@example.com", blocked_at: nil)
    blocked.reload.unblock!
    assert_nil blocked.reload.blocked_at
  end
end
