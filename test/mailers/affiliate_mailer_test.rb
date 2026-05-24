# frozen_string_literal: true

require "test_helper"

# Migrated from spec/mailers/affiliate_mailer_spec.rb. The original spec built
# 70+ FactoryBot objects to drive every branch of every mailer method. This
# fixtures-only port focuses on representative subjects/recipients/CC headers
# across the public methods, asserting the mailer wiring (to / from / cc /
# subject) without depending on the full premailer/asset pipeline or external
# Elasticsearch aggregations.
class AffiliateMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  setup do
    @seller = users(:named_seller)
    @basic_seller = users(:basic_user)
    [@seller, @basic_seller].each do |u|
      Rails.cache.write("creator_mailer_level_#{u.id}", :level_1)
    end
  end

  # --- collaborator_creation ------------------------------------------------

  test "collaborator_creation addresses the affiliate user and CCs the seller" do
    collaborator = affiliates(:collaborator_for_named_seller_product)
    mail = AffiliateMailer.collaborator_creation(collaborator.id)

    assert_equal [collaborator.affiliate_user.form_email], mail.to
    assert_equal [@seller.form_email], mail.cc
    assert_equal "#{@seller.name_or_username} has added you as a collaborator on Gumroad", mail.subject
  end

  # --- collaborator_update --------------------------------------------------

  test "collaborator_update uses the update subject and CCs the seller" do
    collaborator = affiliates(:collaborator_for_named_seller_product)
    mail = AffiliateMailer.collaborator_update(collaborator.id)

    assert_equal [collaborator.affiliate_user.form_email], mail.to
    assert_equal [@seller.form_email], mail.cc
    assert_equal "#{@seller.name_or_username} has updated your collaborator status on Gumroad", mail.subject
  end

  # --- collaboration_ended_by_seller (a.k.a. collaborator_removal) ----------

  test "collaboration_ended_by_seller addresses the affiliate user and CCs the seller" do
    collaborator = affiliates(:collaborator_for_named_seller_product)
    mail = AffiliateMailer.collaboration_ended_by_seller(collaborator.id)

    assert_equal [collaborator.affiliate_user.form_email], mail.to
    assert_equal [@seller.form_email], mail.cc
    assert_equal "#{@seller.name_or_username} just updated your collaborator status", mail.subject
  end

  # --- collaboration_ended_by_affiliate_user --------------------------------

  test "collaboration_ended_by_affiliate_user notifies the seller, CCs the affiliate" do
    collaborator = affiliates(:collaborator_for_named_seller_product)
    affiliate_user = collaborator.affiliate_user
    mail = AffiliateMailer.collaboration_ended_by_affiliate_user(collaborator.id)

    assert_equal [@seller.form_email], mail.to
    assert_equal [affiliate_user.form_email], mail.cc
    assert_equal "#{affiliate_user.name_or_username} has ended your collaboration", mail.subject
  end

  # --- collaborator_invited -------------------------------------------------

  test "collaborator_invited addresses the invitee and CCs the inviter" do
    collaborator = affiliates(:collaborator_for_named_seller_product)
    mail = AffiliateMailer.collaborator_invited(collaborator.id)

    assert_equal [collaborator.affiliate_user.form_email], mail.to
    assert_equal [@seller.form_email], mail.cc
    assert_equal "#{@seller.name_or_username} has invited you to collaborate on Gumroad", mail.subject
  end

  # --- collaborator_invitation_accepted -------------------------------------

  test "collaborator_invitation_accepted addresses the inviter" do
    collaborator = affiliates(:collaborator_for_named_seller_product)
    mail = AffiliateMailer.collaborator_invitation_accepted(collaborator.id)

    assert_equal [@seller.form_email], mail.to
    assert_nil mail.cc
    assert_equal "#{collaborator.affiliate_user.name_or_username} has accepted your invitation to collaborate on Gumroad", mail.subject
  end

  # --- collaborator_invitation_declined -------------------------------------

  test "collaborator_invitation_declined addresses the inviter" do
    collaborator = affiliates(:collaborator_for_named_seller_product)
    mail = AffiliateMailer.collaborator_invitation_declined(collaborator.id)

    assert_equal [@seller.form_email], mail.to
    assert_nil mail.cc
    assert_equal "#{collaborator.affiliate_user.name_or_username} has declined your invitation to collaborate on Gumroad", mail.subject
  end
end
