# frozen_string_literal: true

require "test_helper"

class Admin::ScheduledPayoutPresenterTest < ActiveSupport::TestCase
  test "#props returns the existing scheduled payout shape without enrichment" do
    seller = users(:scheduled_payout_seller)
    seller.update_column(:external_id, "schedpayseller") if seller.external_id.blank?
    scheduled_payout = scheduled_payouts(:named_scheduled_payout)
    scheduled_payout.update_column(:external_id, "schedpay1") if scheduled_payout.external_id.blank?

    props = Admin::ScheduledPayoutPresenter.new(scheduled_payout:).props

    assert_equal scheduled_payout.external_id, props[:external_id]
    assert_equal scheduled_payout.action, props[:action]
    assert_equal scheduled_payout.status, props[:status]
    assert_equal scheduled_payout.delay_days, props[:delay_days]
    assert_equal scheduled_payout.scheduled_at, props[:scheduled_at]
    assert_equal scheduled_payout.executed_at, props[:executed_at]
    assert_equal scheduled_payout.payout_amount_cents, props[:payout_amount_cents]
    assert_equal scheduled_payout.created_at, props[:created_at]
    assert_equal({
                   external_id: seller.external_id,
                   email: seller.form_email,
                   name: "Seller One"
                 }, props[:user])
    assert_equal({ name: "Admin One" }, props[:created_by])
  end

  test "#props adds enrichment without changing existing keys" do
    scheduled_payout = scheduled_payouts(:bare_scheduled_payout)
    enrichment = {
      product_count: 2,
      incoming_affiliate_count: 3,
      risk_state: { status: "Compliant" },
      top_categories: [{ slug: "design", product_count: 2 }],
      unpaid_balance_cents: 12_345,
      unpaid_balance_formatted: "$123.45",
    }
    original_props = Admin::ScheduledPayoutPresenter.new(scheduled_payout:).props

    enriched_props = Admin::ScheduledPayoutPresenter.new(scheduled_payout:, enrichment:).props

    assert_equal original_props, enriched_props.except(*enrichment.keys)
    enrichment.each { |k, v| assert_equal v, enriched_props[k] }
  end
end
