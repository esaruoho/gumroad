require "test_helper"

class InviteTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @sender = users(:named_seller)
  end

  test "#invitation_sent scope returns only records with status invitation_sent" do
    invite_sent = Invite.create!(user: @sender, receiver_email: "sent@example.com")
    invite_signed_up = Invite.create!(user: @sender, receiver_email: "signed@example.com", invite_state: "signed_up")
    scope_ids = Invite.invitation_sent.where(id: [invite_sent.id, invite_signed_up.id]).pluck(:id)
    assert_equal [invite_sent.id], scope_ids
  end

  test "#signed_up scope returns only records with status signed_up" do
    invite_sent = Invite.create!(user: @sender, receiver_email: "sent2@example.com")
    invite_signed_up = Invite.create!(user: @sender, receiver_email: "signed2@example.com", invite_state: "signed_up")
    scope_ids = Invite.signed_up.where(id: [invite_sent.id, invite_signed_up.id]).pluck(:id)
    assert_equal [invite_signed_up.id], scope_ids
  end

  test "#mark_signed_up transitions the status and enqueues an email on success" do
    invite = Invite.create!(user: @sender, receiver_email: "newinvitee@example.com")
    invited_user = users(:basic_user)
    invite.update!(receiver_id: invited_user.id)

    assert_changes -> { invite.reload.signed_up? }, from: false, to: true do
      assert_enqueued_with(job: ActionMailer::MailDeliveryJob, args: ->(args) {
        args[0] == "InviteMailer" && args[1] == "receiver_signed_up" && args[3][:args] == [invite.id]
      }) do
        invite.mark_signed_up
      end
    end
  end

  test "#invite_state_text returns the correct text depending on invite_state" do
    invite = Invite.new(user: @sender, receiver_email: "x@example.com")
    assert_equal "Invitation sent", invite.invite_state_text

    invite.invite_state = "signed_up"
    assert_equal "Signed up!", invite.invite_state_text
  end
end
