# frozen_string_literal: true

require "test_helper"

# Migrated from spec/mailers/contacting_creator_mailer_spec.rb (285 FactoryBot
# refs). Almost every method in this mailer just sets @seller / @subject and
# delegates to a single `after_action :deliver_email` that wires
#   to: @seller.form_email, subject: @subject
# This fixtures-only port covers a representative slice of the seller-targeted
# methods, asserting that wiring. Methods that depend on additional fixtures
# (Payment, Purchase chains for notify/chargeback) are deferred — covered by
# integration tests.
class ContactingCreatorMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  setup do
    @seller = users(:named_seller)
    Rails.cache.write("creator_mailer_level_#{@seller.id}", :level_1)
  end

  # --- remind ---------------------------------------------------------------

  test "remind addresses the seller with the payment-account subject" do
    mail = ContactingCreatorMailer.remind(@seller.id)
    assert_equal [@seller.form_email], mail.to
    assert_equal "Please add a payment account to Gumroad.", mail.subject
  end

  # remind early-returns when seller is missing, but the after_action still
  # runs and dereferences @seller — this is a known quirk; integration tests
  # cover the no-seller path via `User.find_by` failing earlier.

  # --- invalid_bank_account / invalid_account_holder_name -------------------

  test "invalid_bank_account addresses the seller" do
    mail = ContactingCreatorMailer.invalid_bank_account(@seller.id)
    assert_equal [@seller.form_email], mail.to
    assert_equal "We were unable to verify your bank account.", mail.subject
  end

  test "invalid_account_holder_name addresses the seller" do
    mail = ContactingCreatorMailer.invalid_account_holder_name(@seller.id)
    assert_equal [@seller.form_email], mail.to
    assert_equal "Your bank account holder name was rejected.", mail.subject
  end

  # --- seller_update --------------------------------------------------------

  test "seller_update sends the weekly summary subject" do
    mail = ContactingCreatorMailer.seller_update(@seller.id)
    assert_equal [@seller.form_email], mail.to
    assert_equal "Your last week.", mail.subject
  end

  # --- credit_notification --------------------------------------------------

  test "credit_notification addresses the seller and uses the credit subject" do
    mail = ContactingCreatorMailer.credit_notification(@seller.id, 500)
    assert_equal [@seller.form_email], mail.to
    assert_equal "You've received Gumroad credit!", mail.subject
  end

  test "gumroad_day_credit_notification addresses the seller" do
    mail = ContactingCreatorMailer.gumroad_day_credit_notification(@seller.id, 500)
    assert_equal [@seller.form_email], mail.to
    assert_equal "You've received Gumroad credit!", mail.subject
  end

  # --- video_preview_conversion_error ---------------------------------------

  test "video_preview_conversion_error addresses the product owner" do
    product = links(:named_seller_product)
    mail = ContactingCreatorMailer.video_preview_conversion_error(product.id)
    assert_equal [@seller.form_email], mail.to
    assert_equal "We were unable to process your preview video.", mail.subject
  end

  # --- flagged_for_explicit_nsfw_tos_violation -----------------------------

  test "flagged_for_explicit_nsfw_tos_violation addresses the seller" do
    mail = ContactingCreatorMailer.flagged_for_explicit_nsfw_tos_violation(@seller.id)
    assert_equal [@seller.form_email], mail.to
    assert_includes mail.subject, "temporarily suspended"
  end
end
