# frozen_string_literal: true

require "test_helper"

class InviteMailerTest < ActionMailer::TestCase
  setup do
    @sender = users(:named_seller)
    @invite = invites(:basic_user_invite)
    @invited_user = users(:invited_user)
    # Fixture already wires sender_id + receiver_id + receiver_email; no need
    # to call mark_as_invited (which would create a duplicate row).
  end

  test "has the correct 'to' and 'from' values" do
    mail = InviteMailer.receiver_signed_up(@invite.id)
    assert_equal [@sender.form_email], mail.to
    assert_equal [ApplicationMailer::NOREPLY_EMAIL], mail.from
  end

  test "has the correct subject and title when the user has no name set" do
    @invited_user.update_column(:name, nil)
    mail = InviteMailer.receiver_signed_up(@invite.id)
    assert_equal "A creator you invited has joined Gumroad.", mail.subject
    assert_includes mail.body.encoded, "A creator you invited has joined Gumroad."
  end

  test "has the correct subject and title when the user has a name set" do
    @invited_user.name = "Sam Smith"
    @invited_user.save!
    mail = InviteMailer.receiver_signed_up(@invite.id)
    assert_equal "#{@invited_user.name} has joined Gumroad, thanks to you.", mail.subject
    assert_includes mail.body.encoded, "#{@invited_user.name} has joined Gumroad, thanks to you."
  end

  test "does not attempt to send an email if the 'to' email is empty" do
    @sender.update_column(:email, nil)
    assert_no_difference -> { ActionMailer::Base.deliveries.count } do
      InviteMailer.receiver_signed_up(@invite.id).deliver_now
    end
  end

  test "has both username and email in body" do
    @invited_user.name = "Sam Smith"
    @invited_user.save!
    mail = InviteMailer.receiver_signed_up(@invite.id)
    assert_includes mail.body.encoded, "#{@invited_user.name} - #{@invited_user.email}"
  end
end
