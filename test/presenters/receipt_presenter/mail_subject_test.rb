# frozen_string_literal: true

require "test_helper"

class ReceiptPresenter
  class MailSubjectTest < ActiveSupport::TestCase
    setup do
      @purchase = purchases(:named_seller_call_purchase)
      @product = @purchase.link
    end

    def build_subject
      ReceiptPresenter::MailSubject.build(@purchase)
    end

    test ".build returns 'You bought ...' for a paid single purchase" do
      assert_equal "You bought #{@product.name}!", build_subject
    end

    test ".build returns 'You got ...' for a free purchase" do
      @purchase.update_columns(price_cents: 0)
      assert_equal "You got #{@product.name}!", build_subject
    end

    test ".build returns 'You rented ...' for a rental" do
      @purchase.update_columns(flags: (@purchase.flags || 0) | (1 << 14)) # is_rental (has_flags 15 = bit 14)
      assert_equal "You rented #{@product.name}!", build_subject
    end

    test "subscription subject for first-purchase membership" do
      @product.update_columns(flags: (@product.flags || 0) | Link.flag_mapping["flags"][:is_recurring_billing])
      assert_equal "You've subscribed to #{@product.name}!", build_subject
    end

    test ".build returns recurring charge subject" do
      @product.update_columns(flags: (@product.flags || 0) | Link.flag_mapping["flags"][:is_recurring_billing])
      sub_id = Subscription.connection.insert(<<~SQL.squish)
        INSERT INTO subscriptions (link_id, user_id, created_at, updated_at)
        VALUES (#{@product.id}, #{@purchase.purchaser_id || "NULL"}, NOW(), NOW())
      SQL
      @purchase.update_columns(subscription_id: sub_id)
      assert_equal "Recurring charge for #{@product.name}.", build_subject
    end

    test ".build returns upgrade subject" do
      @product.update_columns(flags: (@product.flags || 0) | Link.flag_mapping["flags"][:is_recurring_billing])
      @purchase.update_columns(
        flags: (@purchase.flags || 0) | (1 << 11) # is_upgrade_purchase (has_flags 12 = bit 11)
      )
      assert_equal "You've upgraded your membership for #{@product.name}!", build_subject
    end
  end
end
