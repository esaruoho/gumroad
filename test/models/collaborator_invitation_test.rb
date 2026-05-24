require "test_helper"

class CollaboratorInvitationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def make_collaborator(seller: users(:purchaser), affiliate_user: users(:community_buyer))
    Collaborator.create!(
      seller: seller,
      affiliate_user: affiliate_user,
      apply_to_all_products: true,
      affiliate_basis_points: 30_00,
    )
  end

  test "#accept! destroys the invitation" do
    collaborator = make_collaborator
    invitation = CollaboratorInvitation.create!(collaborator: collaborator)

    assert_difference -> { CollaboratorInvitation.count }, -1 do
      invitation.accept!
    end
    assert_raises(ActiveRecord::RecordNotFound) { invitation.reload }
  end

  test "#accept! sends a notification email" do
    collaborator = make_collaborator
    invitation = CollaboratorInvitation.create!(collaborator: collaborator)

    assert_enqueued_with(job: ActionMailer::MailDeliveryJob, args: ->(args) {
      args[0] == "AffiliateMailer" && args[1] == "collaborator_invitation_accepted"
    }) do
      invitation.accept!
    end
  end

  test "#decline! marks the collaborator as deleted" do
    collaborator = make_collaborator
    invitation = CollaboratorInvitation.create!(collaborator: collaborator)

    assert_equal false, collaborator.reload.deleted?
    invitation.decline!
    assert_equal true, collaborator.reload.deleted?
  end

  test "#decline! disables the is_collab flag on associated products" do
    seller = users(:purchaser)
    collaborator = make_collaborator(seller: seller)
    invitation = CollaboratorInvitation.create!(collaborator: collaborator)

    product_one = Link.create!(user: seller, name: "Collab P1", price_cents: 100, is_collab: true)
    product_two = Link.create!(user: seller, name: "Collab P2", price_cents: 100, is_collab: true)
    ProductAffiliate.create!(product: product_one, affiliate: collaborator, affiliate_basis_points: 30_00)
    ProductAffiliate.create!(product: product_two, affiliate: collaborator, affiliate_basis_points: 30_00)

    assert_equal true, product_one.reload.is_collab
    assert_equal true, product_two.reload.is_collab

    invitation.decline!

    assert_equal false, product_one.reload.is_collab
    assert_equal false, product_two.reload.is_collab
  end

  test "#decline! sends an email to the collaborator" do
    collaborator = make_collaborator
    invitation = CollaboratorInvitation.create!(collaborator: collaborator)

    assert_enqueued_with(job: ActionMailer::MailDeliveryJob, args: ->(args) {
      args[0] == "AffiliateMailer" && args[1] == "collaborator_invitation_declined"
    }) do
      invitation.decline!
    end
  end
end
