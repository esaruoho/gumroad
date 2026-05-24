require "test_helper"

class CreatorContactingCustomersEmailInfoTest < ActiveSupport::TestCase
  setup do
    @purchase = purchases(:auto_invoice_enabled_purchase)
    @installment = installments(:pcp_post)
  end

  def build_email_info(state: "created", **overrides)
    CreatorContactingCustomersEmailInfo.create!(
      purchase: @purchase,
      installment: @installment,
      email_name: "purchase_installment",
      state: state,
      **overrides,
    )
  end

  test "transitions to sent" do
    email_info = build_email_info
    email_info.update_attribute(:delivered_at, Time.current)
    assert_equal "purchase_installment", email_info.email_name
    email_info.mark_sent!
    assert_equal "sent", email_info.reload.state
    assert email_info.reload.sent_at.present?
    assert_nil email_info.reload.delivered_at
  end

  test "transitions to delivered" do
    email_info = build_email_info(state: "sent", sent_at: Time.current)
    assert email_info.sent_at.present?
    assert_nil email_info.delivered_at
    assert_nil email_info.opened_at
    email_info.mark_delivered!
    assert_equal "delivered", email_info.reload.state
    assert email_info.reload.delivered_at.present?
  end

  test "transitions to opened" do
    email_info = build_email_info(state: "delivered", sent_at: Time.current, delivered_at: Time.current)
    assert email_info.sent_at.present?
    assert email_info.delivered_at.present?
    assert_nil email_info.opened_at
    email_info.mark_opened!
    assert_equal "opened", email_info.reload.state
    assert email_info.reload.opened_at.present?
  end

  test "transitions to bounced and then sent" do
    email_info = build_email_info(state: "sent", sent_at: Time.current)
    email_info.mark_bounced!
    assert_equal "bounced", email_info.reload.state
    assert email_info.reload.sent_at.present?
    email_info.mark_sent!
    assert_equal "sent", email_info.reload.state
    assert email_info.reload.sent_at.present?
  end

  test "mark_bounced! attempts to unsubscribe the buyer of the purchase" do
    email_info = build_email_info(state: "sent", sent_at: Time.current)
    assert @purchase.can_contact?
    email_info.mark_bounced!
    # unsubscribe_buyer flips can_contact to false on matching purchases
    assert_equal false, @purchase.reload.can_contact?
  end
end
