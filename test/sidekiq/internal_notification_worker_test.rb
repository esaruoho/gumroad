# frozen_string_literal: true

require "test_helper"

class InternalNotificationWorkerTest < ActiveSupport::TestCase
  test "sends an email via InternalNotificationMailer" do
    captured = nil
    mailer = Minitest::Mock.new
    mailer.expect(:deliver_now, nil)

    InternalNotificationMailer.stub(:notify, ->(**kwargs) { captured = kwargs; mailer }) do
      InternalNotificationWorker.new.perform("payments", "Test Sender", "Test message", "green")
    end

    assert_equal({
      room_name: "payments",
      sender: "Test Sender",
      message_text: "Test message",
      attachments_data: []
    }, captured)
    assert mailer.verify
  end

  test "passes attachments from options" do
    attachments = [{ "fallback" => "Attachment text", "text" => "Details" }]
    captured = nil
    mailer = Minitest::Mock.new
    mailer.expect(:deliver_now, nil)

    InternalNotificationMailer.stub(:notify, ->(**kwargs) { captured = kwargs; mailer }) do
      InternalNotificationWorker.new.perform("announcements", "Reporter", "Report ready", "gray", { "attachments" => attachments })
    end

    assert_equal({
      room_name: "announcements",
      sender: "Reporter",
      message_text: "Report ready",
      attachments_data: attachments
    }, captured)
    assert mailer.verify
  end
end
