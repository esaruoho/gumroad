# frozen_string_literal: true

require "test_helper"

class UserSignupMailerTest < ActionMailer::TestCase
  test "includes RescueSmtpErrors" do
    assert UserSignupMailer.include?(RescueSmtpErrors)
  end

  # #confirmation_instructions
  test "confirmation_instructions sets the correct headers" do
    mail = UserSignupMailer.confirmation_instructions(users(:basic_user), {})
    assert_equal "Confirmation instructions", mail.subject
    assert_equal [ApplicationMailer::NOREPLY_EMAIL], mail.from
    assert_equal [ApplicationMailer::NOREPLY_EMAIL], mail.reply_to
  end

  test "confirmation_instructions includes the notification message" do
    mail = UserSignupMailer.confirmation_instructions(users(:basic_user), {})
    body = mail.body.to_s
    assert_includes body, "Confirm your email address"
    assert_includes body, "Please confirm your account by clicking the button below."
    assert_includes body, "If you didn't request this, please ignore this email. You won't get another one!"
  end

  # #email_changed
  test "email_changed sets the correct headers" do
    user = users(:basic_user)
    user.update_columns(email: "original@example.com", unconfirmed_email: "new@example.com")
    mail = UserSignupMailer.email_changed(user)
    assert_equal "Security alert: Your Gumroad account email is being changed", mail.subject
    assert_equal [ApplicationMailer::NOREPLY_EMAIL], mail.from
    assert_equal [ApplicationMailer::NOREPLY_EMAIL], mail.reply_to
  end

  test "email_changed includes the notification message" do
    user = users(:basic_user)
    user.update_columns(email: "original@example.com", unconfirmed_email: "new@example.com")
    mail = UserSignupMailer.email_changed(user)
    body = mail.body.to_s
    assert_includes body, "Your Gumroad account email is being changed"
    assert_includes body, "from original@example.com to new@example.com"
    assert_includes body, "If you did not make this change, please contact support immediately by replying to this email."
    assert_includes body, "User ID: #{user.external_id}"
  end

  # #reset_password_instructions
  test "reset_password_instructions sets the correct headers" do
    mail = UserSignupMailer.reset_password_instructions(users(:basic_user), {})
    assert_equal "Reset password instructions", mail.subject
    assert_equal [ApplicationMailer::NOREPLY_EMAIL], mail.from
    assert_equal [ApplicationMailer::NOREPLY_EMAIL], mail.reply_to
  end

  test "reset_password_instructions includes the notification message" do
    mail = UserSignupMailer.reset_password_instructions(users(:basic_user), {})
    body = mail.body.to_s
    assert_includes body, "Forgotten password request"
    assert_includes body, "It seems you forgot the password for your Gumroad account."
    assert_includes body, "If you didn't request this, please ignore this email. You won't get another one!"
  end
end
