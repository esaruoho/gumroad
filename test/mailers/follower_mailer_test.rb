# frozen_string_literal: true

require "test_helper"

class FollowerMailerTest < ActionMailer::TestCase
  setup do
    @followee = users(:named_seller)
    @unconfirmed_follower = followers(:unconfirmed_follower_of_named_seller)
  end

  test "confirm_follower sends email to follower to confirm the follow" do
    mail = FollowerMailer.confirm_follower(@followee.id, @unconfirmed_follower.id)
    assert_equal ["noreply@staging.followers.gumroad.com"], mail.from
    assert_equal [@unconfirmed_follower.email], mail.to
    assert_equal "Please confirm your follow request.", mail.subject
    confirm_follow_route = Rails.application.routes.url_helpers.confirm_follow_url(
      @unconfirmed_follower.external_id, host: "#{PROTOCOL}://#{DOMAIN}"
    )
    assert_includes mail.body.encoded, confirm_follow_route
  end

  test "confirm_follower sets the correct SendGrid account" do
    creds = {
      MailerInfo::EMAIL_PROVIDER_SENDGRID => {
        followers: {
          address: SENDGRID_SMTP_ADDRESS,
          username: "apikey",
          password: "sendgrid-api-secret",
          domain: FOLLOWER_CONFIRMATION_MAIL_DOMAIN,
        }
      }
    }
    with_const(:EMAIL_CREDENTIALS, creds) do
      mail = FollowerMailer.confirm_follower(@followee.id, @unconfirmed_follower.id)
      assert_equal "apikey", mail.delivery_method.settings[:user_name]
      assert_equal "sendgrid-api-secret", mail.delivery_method.settings[:password]
    end
  end
end
