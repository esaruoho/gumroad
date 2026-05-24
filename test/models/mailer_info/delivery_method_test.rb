# frozen_string_literal: true

require "test_helper"

class MailerInfo::DeliveryMethodTest < ActiveSupport::TestCase
  EMAIL_PROVIDER = MailerInfo::EMAIL_PROVIDER_SENDGRID

  test ".options raises ArgumentError with invalid domain" do
    error = assert_raises(ArgumentError) do
      MailerInfo::DeliveryMethod.options(domain: :invalid, email_provider: EMAIL_PROVIDER)
    end
    assert_equal "Invalid domain: invalid", error.message
  end

  test ".options raises ArgumentError when seller passed for non-customers domain" do
    seller = users(:basic_user)
    error = assert_raises(ArgumentError) do
      MailerInfo::DeliveryMethod.options(domain: :gumroad, email_provider: EMAIL_PROVIDER, seller: seller)
    end
    assert_equal "Seller is only allowed for customers domain", error.message
  end

  test ".options with SendGrid returns basic options" do
    assert_equal({
      address: SENDGRID_SMTP_ADDRESS,
      domain: DEFAULT_EMAIL_DOMAIN,
      user_name: "apikey",
      password: GlobalConfig.get("SENDGRID_GUMROAD_TRANSACTIONS_API_KEY")
    }, MailerInfo::DeliveryMethod.options(domain: :gumroad, email_provider: EMAIL_PROVIDER))
  end

  test ".options with Resend returns basic options" do
    assert_equal({
      address: RESEND_SMTP_ADDRESS,
      domain: DEFAULT_EMAIL_DOMAIN,
      user_name: "resend",
      password: GlobalConfig.get("RESEND_DEFAULT_API_KEY")
    }, MailerInfo::DeliveryMethod.options(domain: :gumroad, email_provider: MailerInfo::EMAIL_PROVIDER_RESEND))
  end

  test ".options with seller returns seller-specific options" do
    seller = users(:basic_user)
    seller.define_singleton_method(:mailer_level) { :level_1 }
    assert_equal({
      address: SENDGRID_SMTP_ADDRESS,
      domain: CUSTOMERS_MAIL_DOMAIN,
      user_name: "apikey",
      password: GlobalConfig.get("SENDGRID_GR_CUSTOMERS_API_KEY")
    }, MailerInfo::DeliveryMethod.options(domain: :customers, email_provider: EMAIL_PROVIDER, seller: seller))
  end
end
