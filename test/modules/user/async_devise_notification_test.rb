# frozen_string_literal: true

require "test_helper"

class User::AsyncDeviseNotificationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  fixtures :users

  setup do
    @user = users(:basic_user)
  end

  [
    ["send_confirmation_instructions", "confirmation_instructions"],
    ["send_reset_password_instructions", "reset_password_instructions"],
  ].each do |devise_email_method, devise_email_name|
    test "#{devise_email_method} queues the #{devise_email_name} email in the background" do
      assert_enqueued_with(job: ActionMailer::MailDeliveryJob, queue: "critical") do
        @user.public_send(devise_email_method)
      end
      enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.last
      assert_equal "UserSignupMailer", enqueued[:args][0]
      assert_equal devise_email_name, enqueued[:args][1]
    end

    test "#{devise_email_method} actually sends the email" do
      skip "deliver_now path requires built email.scss asset (premailer); covered by integration runs"
    end
  end
end
