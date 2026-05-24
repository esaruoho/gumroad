# frozen_string_literal: true

require "test_helper"

class CreatorMailerTopCreatorAnnouncementTest < ActionMailer::TestCase
  test "doesn't send email if user does not exist" do
    mail = CreatorMailer.top_creator_announcement(user_id: 0)
    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end

  test "doesn't send email if user has been marked as deleted" do
    mail = CreatorMailer.top_creator_announcement(user_id: users(:deleted_user).id)
    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end

  test "doesn't send email if user is suspended" do
    mail = CreatorMailer.top_creator_announcement(user_id: users(:suspended_user).id)
    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end

  test "doesn't send email if user's email is invalid" do
    user = users(:basic_user)
    user.update_column(:email, "notvalid")
    mail = CreatorMailer.top_creator_announcement(user_id: user.id)
    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end

  test "sets correct attributes" do
    user = users(:basic_user)
    mail = CreatorMailer.top_creator_announcement(user_id: user.id)
    assert_equal [user.form_email], mail.to
    assert_equal ["gumroad@#{CREATOR_CONTACTING_CUSTOMERS_MAIL_DOMAIN}"], mail.from
    assert_equal "You're a Top Creator!", mail.subject
  end

  test "includes the badge image and announcement copy in the body" do
    user = users(:basic_user)
    mail = CreatorMailer.top_creator_announcement(user_id: user.id)
    body = mail.body.to_s
    assert_includes body, "top_creator_badge"
    assert_includes body, "You just earned the Top Creator badge on Gumroad."
  end
end
