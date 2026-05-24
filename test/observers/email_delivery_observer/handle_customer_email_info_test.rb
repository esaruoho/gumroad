# frozen_string_literal: true

require "test_helper"

class EmailDeliveryObserver::HandleCustomerEmailInfoTest < ActiveSupport::TestCase
  # The original RSpec suite (spec/observers/email_delivery_observer/handle_customer_email_info_spec.rb)
  # exercised the full SendGrid/Resend × Receipt/Preorder × Purchase/Charge matrix
  # by calling `CustomerMailer.<method>(...).deliver_now`. The Minitest CI lane
  # doesn't build Vite assets, so `deliver_now` blows up in Premailer's email.scss
  # lookup (see gumroad-fixtures-migration pitfall #13).
  #
  # The unit under test is `EmailDeliveryObserver::HandleCustomerEmailInfo.perform(message)`.
  # Its inputs are entirely the message headers, so we synthesize a Mail::Message
  # with the expected SendGrid / Resend header shape. The CustomerMailer interaction
  # is covered by integration tests.

  setup do
    @purchase = purchases(:auto_invoice_enabled_purchase)
    @charge   = charges(:admin_charge_policy_charge)
    CustomerEmailInfo.delete_all
    EmailInfoCharge.delete_all
  end

  # -- SendGrid path -----------------------------------------------------------

  test "SendGrid + Purchase: creates a CustomerEmailInfo and marks it sent when none exists" do
    message = build_sendgrid_message(mailer_method: "receipt", purchase_id: @purchase.id)

    assert_difference -> { CustomerEmailInfo.count }, 1 do
      EmailDeliveryObserver::HandleCustomerEmailInfo.perform(message)
    end

    info = CustomerEmailInfo.last
    assert_equal @purchase.id, info.purchase_id
    assert_equal "receipt", info.email_name
    assert_predicate info.sent_at, :present?
  end

  test "SendGrid + Purchase: finds the existing CustomerEmailInfo and marks it sent" do
    existing = CustomerEmailInfo.create!(purchase: @purchase, email_name: "receipt")
    message  = build_sendgrid_message(mailer_method: "receipt", purchase_id: @purchase.id)

    assert_no_difference -> { CustomerEmailInfo.count } do
      EmailDeliveryObserver::HandleCustomerEmailInfo.perform(message)
    end

    assert_predicate existing.reload.sent_at, :present?
  end

  test "SendGrid + Charge: creates a CustomerEmailInfo bound to the charge when none exists" do
    message = build_sendgrid_message(mailer_method: "receipt", charge_id: @charge.id)

    assert_difference -> { CustomerEmailInfo.count }, 1 do
      EmailDeliveryObserver::HandleCustomerEmailInfo.perform(message)
    end

    info = CustomerEmailInfo.last
    assert_nil info.purchase_id
    assert_equal @charge.id, info.email_info_charge.charge_id
    assert_equal "receipt", info.email_name
    assert_predicate info.sent_at, :present?
  end

  test "SendGrid + Charge: finds the existing CustomerEmailInfo bound to the charge and marks sent" do
    existing = CustomerEmailInfo.new(email_name: "receipt")
    existing.build_email_info_charge(charge_id: @charge.id)
    existing.save!

    message = build_sendgrid_message(mailer_method: "receipt", charge_id: @charge.id)
    assert_no_difference -> { CustomerEmailInfo.count } do
      EmailDeliveryObserver::HandleCustomerEmailInfo.perform(message)
    end
    assert_predicate existing.reload.sent_at, :present?
  end

  test "SendGrid: ignores messages without purchase_id or charge_id" do
    message = build_sendgrid_message(mailer_method: "grouped_receipt")
    assert_no_difference -> { CustomerEmailInfo.count } do
      assert_nothing_raised { EmailDeliveryObserver::HandleCustomerEmailInfo.perform(message) }
    end
  end

  test "SendGrid: notifies the error tracker when the X-SMTPAPI header is invalid JSON" do
    message = Mail.new
    message[MailerInfo.header_name(:email_provider)] = MailerInfo::EMAIL_PROVIDER_SENDGRID
    message[MailerInfo::SENDGRID_X_SMTPAPI_HEADER]   = "not-json"

    notified = []
    ErrorNotifier.stub(:notify, ->(err, **_kw) { notified << err }) do
      assert_no_difference -> { CustomerEmailInfo.count } do
        assert_nothing_raised { EmailDeliveryObserver::HandleCustomerEmailInfo.perform(message) }
      end
    end

    assert_equal 1, notified.size
    assert_kind_of EmailDeliveryObserver::HandleCustomerEmailInfo::InvalidHeaderError, notified.first
    assert_match(/Failed to parse sendgrid header/, notified.first.message)
  end

  # -- Resend path -------------------------------------------------------------

  test "Resend + Purchase: creates a CustomerEmailInfo and marks it sent" do
    message = build_resend_message(mailer_method: "receipt", purchase_id: @purchase.id)
    assert_difference -> { CustomerEmailInfo.count }, 1 do
      EmailDeliveryObserver::HandleCustomerEmailInfo.perform(message)
    end
    info = CustomerEmailInfo.last
    assert_equal @purchase.id, info.purchase_id
    assert_equal "receipt", info.email_name
    assert_predicate info.sent_at, :present?
  end

  test "Resend: notifies the error tracker when a required header is missing" do
    # X-GUM-Mailer-Method is required; omit it to trigger the InvalidHeaderError path.
    message = Mail.new
    message[MailerInfo.header_name(:email_provider)] = MailerInfo::EMAIL_PROVIDER_RESEND
    # No mailer_method header at all.

    notified = []
    ErrorNotifier.stub(:notify, ->(err, **_kw) { notified << err }) do
      assert_no_difference -> { CustomerEmailInfo.count } do
        assert_nothing_raised { EmailDeliveryObserver::HandleCustomerEmailInfo.perform(message) }
      end
    end
    assert_equal 1, notified.size
    assert_kind_of EmailDeliveryObserver::HandleCustomerEmailInfo::InvalidHeaderError, notified.first
    assert_match(/Failed to parse resend header/, notified.first.message)
  end

  private
    def build_sendgrid_message(mailer_method:, purchase_id: nil, charge_id: nil)
      unique_args = { "mailer_class" => "CustomerMailer", "mailer_method" => mailer_method }
      unique_args["purchase_id"] = purchase_id if purchase_id
      unique_args["charge_id"]   = charge_id   if charge_id

      message = Mail.new
      message[MailerInfo.header_name(:email_provider)] = MailerInfo::EMAIL_PROVIDER_SENDGRID
      message[MailerInfo::SENDGRID_X_SMTPAPI_HEADER]   = { "unique_args" => unique_args }.to_json
      message
    end

    def build_resend_message(mailer_method:, purchase_id: nil, charge_id: nil)
      message = Mail.new
      message[MailerInfo.header_name(:email_provider)] = MailerInfo::EMAIL_PROVIDER_RESEND
      message[MailerInfo.header_name(:mailer_method)]  = MailerInfo.encrypt(mailer_method)
      message[MailerInfo.header_name(:purchase_id)]    = MailerInfo.encrypt(purchase_id.to_s) if purchase_id
      message[MailerInfo.header_name(:charge_id)]      = MailerInfo.encrypt(charge_id.to_s)   if charge_id
      message
    end
end
