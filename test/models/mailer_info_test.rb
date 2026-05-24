# frozen_string_literal: true

require "test_helper"

class MailerInfoTest < ActiveSupport::TestCase
  test ".header_name formats valid header names" do
    assert_equal "X-GUM-Email-Provider", MailerInfo.header_name(:email_provider)
    assert_equal "X-GUM-Mailer-Class", MailerInfo.header_name(:mailer_class)
  end

  test ".header_name raises error for invalid header names" do
    error = assert_raises(ArgumentError) { MailerInfo.header_name(:invalid) }
    assert_match(/Invalid header field/, error.message)
  end

  test ".encrypt delegates to Encryption" do
    MailerInfo::Encryption.stub(:encrypt, ->(v) { assert_equal "test", v; "encrypted" }) do
      assert_equal "encrypted", MailerInfo.encrypt("test")
    end
  end

  test ".decrypt delegates to Encryption" do
    MailerInfo::Encryption.stub(:decrypt, ->(v) { assert_equal "encrypted", v; "test" }) do
      assert_equal "test", MailerInfo.decrypt("encrypted")
    end
  end

  test ".parse_resend_webhook_header finds and decrypts header value" do
    headers = [
      { "name" => "X-GUM-Environment", "value" => "encrypted_env" },
      { "name" => "X-GUM-Mailer-Class", "value" => "encrypted_class" }
    ]
    MailerInfo.stub(:decrypt, ->(v) { assert_equal "encrypted_class", v; "TestMailer" }) do
      assert_equal "TestMailer", MailerInfo.parse_resend_webhook_header(headers, :mailer_class)
    end
  end

  test ".parse_resend_webhook_header returns nil for missing header" do
    headers = [
      { "name" => "X-GUM-Environment", "value" => "encrypted_env" },
      { "name" => "X-GUM-Mailer-Class", "value" => "encrypted_class" }
    ]
    assert_nil MailerInfo.parse_resend_webhook_header(headers, :workflow_ids)
  end

  test ".parse_resend_webhook_header returns nil for nil headers" do
    assert_nil MailerInfo.parse_resend_webhook_header(nil, :mailer_class)
  end

  test ".random_email_provider delegates to Router" do
    MailerInfo::Router.stub(:determine_email_provider, ->(d) { assert_equal :gumroad, d; "sendgrid" }) do
      assert_equal "sendgrid", MailerInfo.random_email_provider(:gumroad)
    end
  end

  test ".random_delivery_method_options gets provider from Router and delegates to DeliveryMethod" do
    MailerInfo.stub(:random_email_provider, ->(d) { assert_equal :gumroad, d; "sendgrid" }) do
      MailerInfo::DeliveryMethod.stub(:options, ->(**kwargs) {
        assert_equal :gumroad, kwargs[:domain]
        assert_equal "sendgrid", kwargs[:email_provider]
        assert_nil kwargs[:seller]
        { address: "smtp.sendgrid.net" }
      }) do
        assert_equal({ address: "smtp.sendgrid.net" },
                     MailerInfo.random_delivery_method_options(domain: :gumroad, seller: nil))
      end
    end
  end

  test ".default_delivery_method_options uses SendGrid as provider" do
    MailerInfo::DeliveryMethod.stub(:options, ->(**kwargs) {
      assert_equal :gumroad, kwargs[:domain]
      assert_equal MailerInfo::EMAIL_PROVIDER_SENDGRID, kwargs[:email_provider]
      { address: "smtp.sendgrid.net" }
    }) do
      assert_equal({ address: "smtp.sendgrid.net" },
                   MailerInfo.default_delivery_method_options(domain: :gumroad))
    end
  end
end
