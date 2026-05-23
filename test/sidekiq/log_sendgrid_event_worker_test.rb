# frozen_string_literal: true

require "test_helper"

class LogSendgridEventWorkerTest < ActiveSupport::TestCase
  setup do
    EmailEvent.delete_all
    @email = "example@example.com"
    @email_digest = Digest::SHA1.hexdigest(@email).first(12)
    @event_timestamp = 5.minutes.from_now
    Feature.activate(:log_email_events)
    EmailEvent.log_send_events(@email, Time.current)
  end

  test "logs open event" do
    params = { "_json" => [{ "event" => "open", "email" => @email, "timestamp" => @event_timestamp }] }
    LogSendgridEventWorker.new.perform(params)

    record = EmailEvent.find_by(email_digest: @email_digest)
    assert_equal 1, record.open_count
    assert_equal 0, record.unopened_emails_count
    assert_nil record.first_unopened_email_sent_at
    assert_equal @event_timestamp.to_i, record.last_opened_at.to_i
  end

  test "logs click event" do
    params = { "_json" => [{ "event" => "click", "email" => @email, "timestamp" => @event_timestamp }] }
    LogSendgridEventWorker.new.perform(params)

    record = EmailEvent.find_by(email_digest: @email_digest)
    assert_equal 1, record.click_count
    assert_equal @event_timestamp.to_i, record.last_clicked_at.to_i
  end
end
