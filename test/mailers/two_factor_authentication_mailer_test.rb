# frozen_string_literal: true

require "test_helper"

class TwoFactorAuthenticationMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  def user
    @user ||= users(:two_factor_user)
  end

  test "has all required information" do
    mail = TwoFactorAuthenticationMailer.authentication_token(user.id)
    assert_equal [user.email], mail.to
    assert_includes mail.subject, "Your authentication token is #{user.otp_code}"
    assert_includes mail.body.to_s, user.otp_code
    # The token is redacted in the URL by ParamsFilter; assert the link path/host instead.
    body = mail.body.to_s
    assert_includes body, "/two-factor/verify.html"
    assert_includes body, "user_id=#{ERB::Util.url_encode(user.encrypted_external_id)}"
    assert_includes body, "This authentication token and login link will expire in 10 minutes."
  end

  test "uses SendGrid delivery method when email_provider is nil (default)" do
    mail = TwoFactorAuthenticationMailer.authentication_token(user.id, email_provider: nil)
    assert_equal SENDGRID_SMTP_ADDRESS, mail.delivery_method.settings[:address]
  end

  test "uses Resend delivery method when email_provider is Resend" do
    mail = TwoFactorAuthenticationMailer.authentication_token(user.id, email_provider: MailerInfo::EMAIL_PROVIDER_RESEND)
    assert_equal RESEND_SMTP_ADDRESS, mail.delivery_method.settings[:address]
  end
end
