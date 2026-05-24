# frozen_string_literal: true

require "test_helper"

class CommunityChatRecapMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  setup do
    @user = users(:community_recap_recipient)
    @seller = users(:community_recap_seller)
    @community = communities(:snap_app_community)
    @community2 = communities(:bubbles_app_community)
    @seller.update_column(:external_id, "extid_recap_seller") if @seller.external_id.blank?
    @user.update_column(:external_id, "extid_recap_user") if @user.external_id.blank?
  end

  # ---------------- daily ----------------

  test "daily recap email" do
    recap = community_chat_recaps(:daily_snap_recap)
    mail = CommunityChatRecapMailer.community_chat_recap_notification(@user.id, @seller.id, [recap.id])

    assert_equal [@user.form_email], mail.to
    assert_equal "Your daily John Doe community recap: March 26, 2025", mail.subject

    body = mail.body.to_s
    assert_includes body, "Here&#39;s a quick daily summary of what&#39;s been happening in John Doe community."
    assert_includes body, "# "
    assert_includes body, "Snap app"

    encoded = mail.body.encoded
    assert_includes encoded, "<li>Creator welcomed everyone to the community.</li>"
    assert_includes encoded, "<li>A customer asked about using <strong>a specific feature</strong>.</li>"
    assert_includes encoded, "<li>Creator provided detailed instructions on how to use the feature.</li>"
    assert_includes encoded, "<li>Two customers expressed their gratitude for the information and help.</li>"
    assert_includes encoded, "10 messages summarised"
    assert_includes encoded, %(href="#{community_url(@seller.external_id, @community.external_id)}")
    assert_includes body, "You are receiving this email because you're part of the John Doe community. To stop receiving daily recap emails, please"
    assert_includes encoded, %(href="#{community_url(@seller.external_id, @community.external_id, notifications: "true")}")
  end

  # ---------------- weekly ----------------

  test "weekly recap email with multiple recaps" do
    weekly = community_chat_recaps(:weekly_snap_recap)
    weekly2 = community_chat_recaps(:weekly_bubbles_recap)
    mail = CommunityChatRecapMailer.community_chat_recap_notification(@user.id, @seller.id, [weekly.id, weekly2.id])

    assert_equal [@user.form_email], mail.to
    assert_equal "Your weekly John Doe community recap: March 17-23, 2025", mail.subject

    body = mail.body.to_s
    assert_includes body, "Here&#39;s a weekly summary of what happened in John Doe community."
    assert_includes body, "Snap app"
    assert_includes body, "Bubbles app"

    encoded = mail.body.encoded
    assert_includes encoded, "The <strong>new version of the app</strong> was shared by the creator"
    assert_includes encoded, "Customers raised concerns regarding various <strong>product issues</strong>"
    assert_includes encoded, "104 messages summarised"
    assert_includes encoded, "<li>Creator welcomed everyone to the community.</li>"
    assert_includes encoded, "<li>People discussed various <strong>product issues</strong>.</li>"
    assert_includes encoded, "24 messages summarised"
    # Pitfall #16: Model.where(id: [...]) is id-ascending; derive expected first
    # community from the same ordering the mailer uses.
    first_community = CommunityChatRecap.where(id: [weekly.id, weekly2.id]).first.community
    assert_includes encoded, %(href="#{community_url(@seller.external_id, first_community.external_id)}")
    assert_includes body, "To stop receiving weekly recap emails"
    assert_includes encoded, %(href="#{community_url(@seller.external_id, first_community.external_id, notifications: "true")}")
  end

  test "weekly recap subject when recap spans multiple months across years" do
    run = CommunityChatRecapRun.create!(
      recap_frequency: "weekly",
      from_date: Date.new(2025, 12, 28).beginning_of_day,
      to_date: Date.new(2026, 1, 3).end_of_day,
    )
    recap = CommunityChatRecap.create!(
      community_chat_recap_run: run,
      community: @community,
      seller: @seller,
      summarized_message_count: 1,
      summary: "<ul><li>x</li></ul>",
      status: "finished",
    )
    mail = CommunityChatRecapMailer.community_chat_recap_notification(@user.id, @seller.id, [recap.id])
    assert_equal "Your weekly John Doe community recap: December 28, 2025-January 3, 2026", mail.subject
  end

  test "weekly recap subject when seller name is nil" do
    @seller.update_column(:name, nil)
    weekly = community_chat_recaps(:weekly_snap_recap)
    mail = CommunityChatRecapMailer.community_chat_recap_notification(@user.id, @seller.id, [weekly.id])
    assert_equal "Your weekly  community recap: March 17-23, 2025", mail.subject
  end

  test "weekly recap subject when recap spans different months in same year" do
    run = CommunityChatRecapRun.create!(
      recap_frequency: "weekly",
      from_date: Date.new(2025, 3, 30).beginning_of_day,
      to_date: Date.new(2025, 4, 5).end_of_day,
    )
    recap = CommunityChatRecap.create!(
      community_chat_recap_run: run,
      community: @community,
      seller: @seller,
      summarized_message_count: 1,
      summary: "<ul><li>x</li></ul>",
      status: "finished",
    )
    mail = CommunityChatRecapMailer.community_chat_recap_notification(@user.id, @seller.id, [recap.id])
    assert_equal "Your weekly John Doe community recap: March 30-April 5, 2025", mail.subject
  end
end
