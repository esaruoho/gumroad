# frozen_string_literal: true

require "test_helper"

class TeamMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  setup do
    @seller = users(:named_seller)
    @team_invitation = team_invitations(:team_invitation_to_member)
  end

  test "invite generates email" do
    mail = TeamMailer.invite(@team_invitation)
    assert_equal [@team_invitation.email], mail.to
    assert_equal "Seller has invited you to join seller", mail.subject
    assert_equal [ApplicationMailer::NOREPLY_EMAIL], mail.from
    assert_equal [@seller.email], mail.reply_to

    assert_includes mail.body.to_s, "This invitation will expire in 7 days."
    assert_includes mail.body.to_s, "Accept invitation"
    assert_includes mail.body.to_s, accept_settings_team_invitation_url(@team_invitation.external_id)
  end

  test "invitation_accepted generates email" do
    user = users(:invited_user)
    team_membership = TeamMembership.create!(seller: @seller, user: user, role: TeamMembership::ROLE_ADMIN)
    mail = TeamMailer.invitation_accepted(team_membership)

    assert_equal [@seller.email], mail.to
    assert_equal "#{user.email} has accepted your invitation", mail.subject
    assert_equal [ApplicationMailer::NOREPLY_EMAIL], mail.from
    assert_equal [user.email], mail.reply_to

    assert_includes mail.body.to_s, "#{user.email} joined the team at seller as Admin"
    assert_includes mail.body.to_s, "Manage your team settings"
    assert_includes mail.body.to_s, settings_team_url
  end
end
