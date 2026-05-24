# frozen_string_literal: true

require "test_helper"

class InternalNotificationMailerTest < ActionMailer::TestCase
  test "sends to the configured email for the room" do
    mail = InternalNotificationMailer.notify(
      room_name: "payments",
      sender: "VAT Reporting",
      message_text: "VAT report generated successfully."
    )
    assert_equal [INTERNAL_NOTIFICATION_EMAIL], mail.to
  end

  test "sets the subject with room name and sender" do
    mail = InternalNotificationMailer.notify(
      room_name: "payments",
      sender: "VAT Reporting",
      message_text: "VAT report generated successfully."
    )
    assert_equal "[test] [payments] VAT Reporting", mail.subject
  end

  test "includes the sender and message in the body" do
    mail = InternalNotificationMailer.notify(
      room_name: "payments",
      sender: "VAT Reporting",
      message_text: "VAT report generated successfully."
    )
    assert_includes mail.body.encoded, "VAT Reporting"
    assert_includes mail.body.encoded, "VAT report generated successfully."
  end

  test "includes attachment content in the body" do
    mail = InternalNotificationMailer.notify(
      room_name: "announcements",
      sender: "Report Bot",
      message_text: "Monthly report",
      attachments_data: [{ "fallback" => "Summary data", "text" => "Details here" }]
    )
    assert_includes mail.body.encoded, "Summary data"
    assert_includes mail.body.encoded, "Details here"
  end

  test "returns a null mail when room has no email configured" do
    mail = InternalNotificationMailer.notify(
      room_name: "nonexistent_room",
      sender: "Test",
      message_text: "Should not send"
    )
    assert_nil mail.to
  end
end
