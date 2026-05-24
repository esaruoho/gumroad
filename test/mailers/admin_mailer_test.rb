# frozen_string_literal: true

require "test_helper"

class AdminMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  setup do
    # Stub User#lost_chargebacks (Elasticsearch aggregations) for the
    # _internal_user_info partial rendered by chargeback_notify / low_balance_notify.
    User.define_method(:lost_chargebacks) { { volume: "$0", count: "0" } } unless User.instance_method(:lost_chargebacks).source_location&.first&.include?("stubbed_by_admin_mailer_test")
    @lost_chargebacks_stub_active = true
  end

  # --- #chargeback_notify (Purchase-disputable) -----------------------------

  test "chargeback_notify for a Purchase: emails risk, has seller details, has purchase details" do
    dispute = disputes(:resolve_still_active_dispute) # formalized + purchase_id
    purchase = dispute.disputable
    mail = AdminMailer.chargeback_notify(dispute.id)

    assert_equal [ApplicationMailer::RISK_EMAIL], mail.to
    body = mail.body.encoded
    assert_includes body, ERB::Util.html_escape(purchase.link.name)
    assert_includes body, purchase.formatted_disputed_amount
    assert_equal "[test] Chargeback for #{purchase.formatted_disputed_amount} on #{purchase.link.name}", mail.subject
  end

  # --- #low_balance_notify --------------------------------------------------

  test "low_balance_notify emails risk with subject, body, and admin links" do
    user = users(:named_seller)
    # The mailer subject interpolates user.balance_formatted, which uses
    # unpaid_balance_cents. Just assert the structure rather than a specific
    # dollar amount.
    purchase = purchases(:audience_purchase)
    mail = AdminMailer.low_balance_notify(user.id, purchase.id)

    assert_equal [ApplicationMailer::RISK_EMAIL], mail.to
    assert_match(/\[test\] Low balance for creator - #{Regexp.escape(user.name)}/, mail.subject)
    body = mail.body.encoded
    assert_includes body, admin_purchase_url(purchase)
    assert_includes body, admin_product_url(purchase.link.unique_permalink)
  end
end
