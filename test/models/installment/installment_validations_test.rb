# frozen_string_literal: true

require "test_helper"

class Installment::InstallmentValidationsTest < ActiveSupport::TestCase
  setup do
    @seller = users(:basic_user)
  end

  # --- #validate_sending_limit_for_sellers ---

  test "valid when seller is sending fewer than the limit and has no sales" do
    inst = Installment.new(seller: @seller, name: "n", message: "<p>m</p>", send_emails: true, installment_type: Installment::SELLER_TYPE)
    inst.define_singleton_method(:audience_members_count) { |_| 0 }
    assert inst.valid?, inst.errors.full_messages.inspect
  end

  test "soft-deleting a post that exceeded the limit is allowed even for a low-revenue seller" do
    inst = Installment.new(seller: @seller, name: "n", message: "<p>m</p>", send_emails: true, installment_type: Installment::SELLER_TYPE)
    inst.define_singleton_method(:audience_members_count) { |_| 0 }
    inst.save!

    inst.define_singleton_method(:audience_members_count) { |_| Installment::SENDING_LIMIT + 1 }
    assert_difference -> { Installment.alive.count }, -1 do
      inst.mark_deleted!
    end
  end

  test "invalid with minimum-sales error when over the limit and under MINIMUM_SALES_CENTS_VALUE" do
    inst = Installment.new(seller: @seller, name: "n", message: "<p>m</p>", send_emails: true, installment_type: Installment::SELLER_TYPE)
    inst.define_singleton_method(:audience_members_count) { |_| Installment::SENDING_LIMIT + 1 }
    @seller.define_singleton_method(:sales_cents_total) { 0 }

    refute inst.valid?
    assert_match(/cannot send out more than #{Installment::SENDING_LIMIT} emails/, inst.errors.full_messages.to_sentence)
  end

  test "abandoned-cart installment skips the sending-limit check" do
    inst = Installment.new(seller: @seller, name: "n", message: "<p>m</p>", send_emails: true,
                           installment_type: Installment::ABANDONED_CART_TYPE)
    inst.define_singleton_method(:audience_members_count) { |_| Installment::SENDING_LIMIT + 1 }
    assert inst.valid?, inst.errors.full_messages.inspect
  end

  test "valid when over the limit but seller has at least MINIMUM_SALES_CENTS_VALUE in sales" do
    inst = Installment.new(seller: @seller, name: "n", message: "<p>m</p>", send_emails: true, installment_type: Installment::SELLER_TYPE)
    inst.define_singleton_method(:audience_members_count) { |_| Installment::SENDING_LIMIT + 1 }
    @seller.define_singleton_method(:sales_cents_total) { Installment::MINIMUM_SALES_CENTS_VALUE }
    assert inst.valid?, inst.errors.full_messages.inspect
  end

  # --- field validations ---

  test "name length cannot exceed 255 characters" do
    inst = Installment.new(seller: @seller, name: "a" * 256, message: "<p>m</p>", installment_type: Installment::SELLER_TYPE)
    refute inst.valid?
    assert_includes inst.errors[:name], "is too long (maximum is 255 characters)"
  end

  test "message must be provided" do
    inst = Installment.new(seller: @seller, name: "n", message: nil,
                           link: links(:basic_user_product), installment_type: Installment::PRODUCT_TYPE,
                           shown_on_profile: true)
    refute inst.valid?
  end

  test "rejects empty HTML-only message content when sending emails" do
    inst = Installment.new(seller: @seller, name: "n", message: "<p><br></p>",
                           link: links(:basic_user_product),
                           installment_type: Installment::PRODUCT_TYPE,
                           send_emails: true)
    inst.define_singleton_method(:audience_members_count) { |_| 0 }
    refute inst.valid?
    assert_includes inst.errors.full_messages, "Please include a message as part of the update."
  end

  # --- #published_at_cannot_be_in_the_future ---

  test "published_at is allowed to be nil" do
    inst = Installment.new(seller: @seller, name: "n", message: "<p>m</p>", installment_type: Installment::SELLER_TYPE,
                           shown_on_profile: true)
    assert_nil inst.published_at
    assert inst.valid?, inst.errors.full_messages.inspect
  end

  test "published_at is allowed to be in the past" do
    inst = Installment.new(seller: @seller, name: "n", message: "<p>m</p>", installment_type: Installment::SELLER_TYPE,
                           shown_on_profile: true, published_at: Time.current)
    assert inst.valid?, inst.errors.full_messages.inspect
  end

  test "published_at cannot be in the future" do
    inst = Installment.new(seller: @seller, name: "n", message: "<p>m</p>", installment_type: Installment::SELLER_TYPE,
                           shown_on_profile: true, published_at: 1.minute.from_now)
    refute inst.valid?
    assert_includes inst.errors.full_messages, "Please enter a publish date in the past."
  end
end
