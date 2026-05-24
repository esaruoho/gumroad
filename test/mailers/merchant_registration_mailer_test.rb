# frozen_string_literal: true

require "test_helper"

class MerchantRegistrationMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  setup do
    @user = users(:basic_user)
    @charge_processor_id = StripeChargeProcessor.charge_processor_id
  end

  # account_deauthorized_to_user

  test "account_deauthorized_to_user has correct subject and body" do
    mail = MerchantRegistrationMailer.account_deauthorized_to_user(@user.id, @charge_processor_id)
    assert_includes mail.subject, "Payments account disconnected - #{@user.external_id}"
    assert_includes mail.body.encoded, @charge_processor_id.capitalize
    assert_includes mail.body.encoded, "Stripe account disconnected"
    assert_includes mail.body.encoded, settings_payments_url
  end

  test "account_deauthorized_to_user shows message for unavailable products" do
    User.any_instance.stubs(:can_publish_products?).returns(false) if defined?(Mocha)
    # Without Mocha — use simple class-level stub
    original = User.instance_method(:can_publish_products?)
    User.define_method(:can_publish_products?) { false }
    begin
      mail = MerchantRegistrationMailer.account_deauthorized_to_user(@user.id, @charge_processor_id)
      assert_includes mail.body.encoded,
        "Because both credit cards and PayPal are now turned off for your account, we've disabled your products for sale. You will have to republish them to enable sales."
    ensure
      User.define_method(:can_publish_products?, original)
    end
  end

  # account_needs_registration_to_user

  test "account_needs_registration_to_user advises affiliate to connect account" do
    affiliate = affiliates(:direct_affiliate_for_helper)
    mail = MerchantRegistrationMailer.account_needs_registration_to_user(affiliate.id, @charge_processor_id)
    assert_includes mail.body.encoded, "You are an affiliate for a creator that has made recent sales"
    assert_includes mail.body.encoded, "connected a #{@charge_processor_id.capitalize} account"
  end

  test "account_needs_registration_to_user advises collaborator to connect account" do
    collaborator = affiliates(:collaborator_for_named_seller_product)
    mail = MerchantRegistrationMailer.account_needs_registration_to_user(collaborator.id, @charge_processor_id)
    assert_includes mail.body.encoded, "You are a collaborator for a creator that has made recent sales"
    assert_includes mail.body.encoded, "connected a #{@charge_processor_id.capitalize} account"
  end

  # stripe_charges_disabled

  test "stripe_charges_disabled alerts user that payments have been disabled" do
    mail = MerchantRegistrationMailer.stripe_charges_disabled(@user.id)
    assert_equal "Action required: Your sales have stopped", mail.subject
    assert_includes mail.to, @user.email
    assert_equal [ApplicationMailer::NOREPLY_EMAIL], mail.from
    assert_includes mail.body.encoded, "We have temporarily disabled payments on your account"
    assert_includes mail.body.encoded, "To resume sales:"
    assert_includes mail.body.encoded, "Submit the required documentation"
    assert_includes mail.body.encoded, "We'll review your information"
    assert_includes mail.body.encoded, "Once the verification is successful"
    assert_includes mail.body.encoded, "Thank you for your patience and understanding."
  end

  # stripe_payouts_disabled

  test "stripe_payouts_disabled notifies user that payouts are paused" do
    mail = MerchantRegistrationMailer.stripe_payouts_disabled(@user.id)
    assert_equal "Action required: Your payouts are paused", mail.subject
    assert_includes mail.to, @user.email
    assert_equal [ApplicationMailer::NOREPLY_EMAIL], mail.from
    assert_includes mail.body.encoded, "We have temporarily paused payouts on your account"
    assert_includes mail.body.encoded, "To resume payouts:"
    assert_includes mail.body.encoded, "Submit the required documentation"
    assert_includes mail.body.encoded, "We'll review your information"
    assert_includes mail.body.encoded, "Once the verification is successful, we'll immediately start processing your payouts again."
    assert_includes mail.body.encoded, "Thank you for your patience and understanding."
  end
end
