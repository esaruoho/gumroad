# frozen_string_literal: true

require "test_helper"

# Migrated from spec/mailers/customer_mailer_spec.rb (168 FactoryBot refs).
# This fixtures-only port covers a representative slice of public methods,
# asserting recipient / subject / reply_to wiring on the constructed Mail
# object. Receipts, grouped_receipt, abandoned_cart, and call/upcoming flows
# depend on the full premailer + presenter chain and are deferred — they have
# coverage via integration tests that exercise the asset pipeline end-to-end.
class CustomerMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  setup do
    @seller = users(:named_seller)
    Rails.cache.write("creator_mailer_level_#{@seller.id}", :level_1)
  end

  # --- refund ---------------------------------------------------------------

  test "refund addresses the customer and uses the refunded subject" do
    purchase = purchases(:audience_purchase)
    mail = CustomerMailer.refund(purchase.email, purchase.link.id, purchase.id)

    assert_equal [purchase.email], mail.to
    assert_equal "You have been refunded.", mail.subject
    assert_includes mail.body.encoded, "You have been refunded."
  end

  # --- paypal_purchase_failed ----------------------------------------------

  test "paypal_purchase_failed addresses the buyer" do
    purchase = purchases(:audience_purchase)
    mail = CustomerMailer.paypal_purchase_failed(purchase.id)

    assert_equal [purchase.email], mail.to
    assert_equal "Your purchase with PayPal failed.", mail.subject
  end

  # --- subscription_magic_link ----------------------------------------------

  test "subscription_magic_link sends to the requested email" do
    subscription = subscriptions(:named_seller_product_subscription)
    mail = CustomerMailer.subscription_magic_link(subscription.id, "customer@example.com")

    assert_equal ["customer@example.com"], mail.to
    assert_equal "Magic Link", mail.subject
  end

  test "subscription_magic_link returns NullMail when email is invalid" do
    subscription = subscriptions(:named_seller_product_subscription)
    mail = CustomerMailer.subscription_magic_link(subscription.id, "notvalid")

    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end
end
