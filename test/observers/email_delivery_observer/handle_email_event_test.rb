# frozen_string_literal: true

require "test_helper"

class EmailDeliveryObserver::HandleEmailEventTest < ActiveSupport::TestCase
  setup do
    skip "EmailEvent is a Mongoid model — MongoDB not available in Minitest CI lane. Covered by RSpec integration."
  end

  test ".perform logs email sent event" do
    user = users(:named_seller)
    email_digest = Digest::SHA1.hexdigest(user.email).first(12)
    timestamp = Time.current

    travel_to timestamp do
      assert_difference -> { EmailEvent.count }, 1 do
        TwoFactorAuthenticationMailer.authentication_token(user.id).deliver_now
      end

      record = EmailEvent.find_by(email_digest:)
      assert_equal 1, record.sent_emails_count
      assert_equal 1, record.unopened_emails_count
      assert_equal timestamp.to_i, record.last_email_sent_at.to_i
      assert_equal timestamp.to_i, record.first_unopened_email_sent_at.to_i
    end
  end
end
