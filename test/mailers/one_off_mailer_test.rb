# frozen_string_literal: true

require "test_helper"

class OneOffMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  setup do
    @email = "seller@example.com"
    @subject = "Email subject"
    @body = "Email body"
    @reply_to = ApplicationMailer::NOREPLY_EMAIL_WITH_NAME
  end

  # #email

  test "email returns NullMail when neither email nor id provided" do
    mail = OneOffMailer.email(subject: @subject, body: @body)
    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end

  test "email returns NullMail when user is deleted" do
    deleted = users(:deleted_user)
    mail = OneOffMailer.email(user_id: deleted.id, subject: @subject, body: @body)
    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end

  test "email returns NullMail when user is suspended" do
    suspended = users(:suspended_user)
    mail = OneOffMailer.email(user_id: suspended.id, subject: @subject, body: @body)
    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end

  test "email returns NullMail when email address is invalid" do
    mail = OneOffMailer.email(email: "notvalid", subject: @subject, body: @body)
    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end

  test "email sets correct attributes" do
    mail = OneOffMailer.email(email: @email, subject: @subject, body: @body)
    assert_includes mail.from, "hi@#{CUSTOMERS_MAIL_DOMAIN}"
    assert_equal @subject, mail.subject
    assert_includes mail.body.encoded, @body
    assert_nil mail.reply_to
  end

  test "email allows safe html tags and strips unsafe ones" do
    mail = OneOffMailer.email(email: @email, subject: @subject, body: %(<a href="http://example.com">link</a><script>alert('hello')</script>))
    assert_includes mail.body.encoded, %(<a href="http://example.com">link</a>)
    refute_includes mail.body.encoded, "<script>"
  end

  test "email sets reply_to header if provided" do
    mail = OneOffMailer.email(email: @email, subject: @subject, body: @body, reply_to: @reply_to)
    assert_includes mail.reply_to, ApplicationMailer::NOREPLY_EMAIL

    mail = OneOffMailer.email(email: @email, subject: @subject, body: @body)
    assert_nil mail.reply_to
  end

  test "email uses default from email when not provided" do
    mail = OneOffMailer.email(email: @email, subject: @subject, body: @body)
    assert_equal ["hi@#{CUSTOMERS_MAIL_DOMAIN}"], mail.from
  end

  test "email uses custom from email when provided" do
    custom_from = "Custom Name <custom@#{CREATOR_CONTACTING_CUSTOMERS_MAIL_DOMAIN}>"
    mail = OneOffMailer.email(email: @email, subject: @subject, body: @body, from: custom_from, sender_domain: "creators")
    assert_equal ["custom@#{CREATOR_CONTACTING_CUSTOMERS_MAIL_DOMAIN}"], mail.from
  end

  test "email uses default sender_domain (customers) when sender_domain not provided" do
    skip "deliver_now path requires built email.scss asset (premailer); covered by integration runs"
  end

  test "email uses custom sender_domain when sender_domain provided" do
    skip "deliver_now path requires built email.scss asset (premailer); covered by integration runs"
  end

  # #email_using_installment

  test "email_using_installment returns NullMail when no recipient given" do
    installment = installments(:published_post)
    mail = OneOffMailer.email_using_installment(subject: @subject, installment_external_id: installment.external_id)
    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end

  test "email_using_installment returns NullMail when user is deleted" do
    installment = installments(:published_post)
    deleted = users(:deleted_user)
    mail = OneOffMailer.email_using_installment(user_id: deleted.id, installment_external_id: installment.external_id)
    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end

  test "email_using_installment returns NullMail when user is suspended" do
    installment = installments(:published_post)
    suspended = users(:suspended_user)
    mail = OneOffMailer.email_using_installment(user_id: suspended.id, installment_external_id: installment.external_id)
    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end

  test "email_using_installment returns NullMail when email is invalid" do
    installment = installments(:published_post)
    mail = OneOffMailer.email_using_installment(email: "notvalid", installment_external_id: installment.external_id)
    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end

  test "email_using_installment uses installment name as subject" do
    installment = installments(:published_post)
    installment.update!(name: "My first installment")
    mail = OneOffMailer.email_using_installment(email: @email, installment_external_id: installment.external_id)
    assert_equal "My first installment", mail.subject
  end

  test "email_using_installment allows overriding the subject" do
    installment = installments(:published_post)
    mail = OneOffMailer.email_using_installment(email: @email, installment_external_id: installment.external_id, subject: "Another subject")
    assert_equal "Another subject", mail.subject
  end

  test "email_using_installment includes installment message" do
    installment = installments(:published_post)
    mail = OneOffMailer.email_using_installment(email: @email, installment_external_id: installment.external_id)
    assert_includes mail.body.encoded, installment.message
  end

  test "email_using_installment sets reply_to header if provided" do
    installment = installments(:published_post)
    mail = OneOffMailer.email_using_installment(email: @email, subject: @subject, installment_external_id: installment.external_id, reply_to: @reply_to)
    assert_includes mail.reply_to, ApplicationMailer::NOREPLY_EMAIL

    mail = OneOffMailer.email(email: @email, subject: @subject, body: @body)
    assert_nil mail.reply_to
  end

  test "email_using_installment does not show the unsubscribe link" do
    installment = installments(:published_post)
    mail = OneOffMailer.email_using_installment(email: @email, installment_external_id: installment.external_id)
    refute_includes mail.body.encoded, "Unsubscribe"
  end
end
