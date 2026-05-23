# frozen_string_literal: true

require "test_helper"

class LogResendEventJobTest < ActiveSupport::TestCase
  setup do
    EmailEvent.delete_all
    @email = "example@example.com"
    @email_digest = Digest::SHA1.hexdigest(@email).first(12)
    @event_timestamp = 5.minutes.from_now
    Feature.activate(:log_email_events)
    EmailEvent.log_send_events(@email, Time.current)
  end

  def base_headers
    [
      { "name" => MailerInfo.header_name(:mailer_class), "value" => MailerInfo.encrypt("Mailer") },
      { "name" => MailerInfo.header_name(:mailer_method), "value" => MailerInfo.encrypt("method") }
    ]
  end

  test "logs open event" do
    params = {
      "type" => "email.opened",
      "created_at" => "2024-02-22T23:41:12.126Z",
      "data" => {
        "created_at" => @event_timestamp.to_s,
        "email_id" => "56761188-7520-42d8-8898-ff6fc54ce618",
        "from" => "Acme <onboarding@resend.dev>",
        "to" => [@email],
        "subject" => "Sending this example",
        "headers" => base_headers
      }
    }
    LogResendEventJob.new.perform(params)

    record = EmailEvent.find_by(email_digest: @email_digest)
    assert_equal 1, record.open_count
    assert_equal 0, record.unopened_emails_count
    assert_nil record.first_unopened_email_sent_at
    assert_equal @event_timestamp.to_i, record.last_opened_at.to_i
  end

  test "logs click event" do
    params = {
      "type" => "email.clicked",
      "created_at" => "2024-11-22T23:41:12.126Z",
      "data" => {
        "created_at" => @event_timestamp.to_s,
        "email_id" => "56761188-7520-42d8-8898-ff6fc54ce618",
        "from" => "Acme <onboarding@resend.dev>",
        "to" => [@email],
        "click" => {
          "ipAddress" => "122.115.53.11",
          "link" => "https://resend.com",
          "timestamp" => "2024-11-24T05:00:57.163Z",
          "userAgent" => "Mozilla/5.0"
        },
        "subject" => "Sending this example",
        "headers" => base_headers
      }
    }
    LogResendEventJob.new.perform(params)

    record = EmailEvent.find_by(email_digest: @email_digest)
    assert_equal 1, record.click_count
    assert_equal @event_timestamp.to_i, record.last_clicked_at.to_i
  end

  test "ignores other event types" do
    params = {
      "type" => "email.delivered",
      "created_at" => "2024-02-22T23:41:12.126Z",
      "data" => {
        "created_at" => @event_timestamp.to_s,
        "email_id" => "56761188-7520-42d8-8898-ff6fc54ce618",
        "from" => "Acme <onboarding@resend.dev>",
        "to" => [@email],
        "subject" => "Sending this example",
        "headers" => base_headers
      }
    }
    LogResendEventJob.new.perform(params)

    record = EmailEvent.find_by(email_digest: @email_digest)
    assert_equal 0, record.open_count
    assert_equal 0, record.click_count
  end
end
