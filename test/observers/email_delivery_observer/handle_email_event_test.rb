# frozen_string_literal: true

require "test_helper"

class EmailDeliveryObserver::HandleEmailEventTest < ActiveSupport::TestCase
  setup do
    EmailEvent.delete_all
  end

  teardown do
    EmailEvent.delete_all
  end

  test ".perform logs email sent event" do
    user = users(:two_factor_user)
    email_digest = Digest::SHA1.hexdigest(user.email).first(12)
    timestamp = Time.current

    # The original spec drove this through `TwoFactorAuthenticationMailer.authentication_token(...).deliver_now`.
    # `.deliver_now` runs the full ActionMailer pipeline, which triggers Premailer's email.scss
    # asset lookup — Vite assets aren't built in `bin/rails test`, so the call explodes with
    # `Premailer::Rails::CSSHelper::FileNotFound` (see gumroad-fixtures-migration pitfall #13).
    #
    # The unit under test is `EmailDeliveryObserver::HandleEmailEvent.perform(message)`, which
    # only reads `message.to` and `message.date`. We synthesize a Mail::Message with that shape
    # — the assertion surface is identical and the observer code path is exercised verbatim.
    message = Mail.new(to: user.email, from: "noreply@gumroad.com", date: timestamp)

    travel_to timestamp do
      assert_difference -> { EmailEvent.count }, 1 do
        EmailDeliveryObserver::HandleEmailEvent.perform(message)
      end

      record = EmailEvent.find_by(email_digest:)
      assert_equal 1, record.sent_emails_count
      assert_equal 1, record.unopened_emails_count
      assert_equal timestamp.to_i, record.last_email_sent_at.to_i
      assert_equal timestamp.to_i, record.first_unopened_email_sent_at.to_i
    end
  end
end
