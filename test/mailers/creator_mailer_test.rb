# frozen_string_literal: true

require "test_helper"

class CreatorMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  setup do
    @seller = users(:named_seller)
    Rails.cache.write("creator_mailer_level_#{@seller.id}", :level_1)
  end

  # --- #gumroad_day_fee_saved ----------------------------------------------

  test "gumroad_day_fee_saved includes details of fee saved" do
    # Stub the seller's fee-saved amount so we don't have to construct a full
    # purchase chain (link + price + timezone) just to hit the formatter.
    User.define_method(:gumroad_day_saved_fee_amount) { "$40.62" }
    begin
      mail = CreatorMailer.gumroad_day_fee_saved(seller_id: @seller.id)
      assert_equal "You saved $40.62 in fees on Gumroad Day!", mail.subject
      body = mail.body.encoded
      assert_includes body, "You saved $40.62 in fees on Gumroad Day!"
    ensure
      User.remove_method(:gumroad_day_saved_fee_amount) if User.instance_methods(false).include?(:gumroad_day_saved_fee_amount)
    end
  end

  test "gumroad_day_fee_saved returns no mail when seller saved nothing" do
    User.define_method(:gumroad_day_saved_fee_amount) { nil }
    begin
      mail = CreatorMailer.gumroad_day_fee_saved(seller_id: @seller.id)
      assert_kind_of ActionMailer::Base::NullMail, mail.message
    ensure
      User.remove_method(:gumroad_day_saved_fee_amount) if User.instance_methods(false).include?(:gumroad_day_saved_fee_amount)
    end
  end

  # --- #bundles_marketing ---------------------------------------------------

  test "bundles_marketing addresses the seller and uses the marketing subject" do
    bundles = [
      {
        type: Product::BundlesMarketing::BEST_SELLING_BUNDLE,
        price: 199_99,
        discounted_price: 99_99,
        products: [
          { id: 1, url: "https://example.com/product1", name: "Best Seller 1" },
          { id: 2, url: "https://example.com/product2", name: "Best Seller 2" },
        ]
      }
    ]
    mail = CreatorMailer.bundles_marketing(seller_id: @seller.id, bundles: bundles)
    assert_equal [@seller.form_email], mail.to
    assert_equal "Join top creators who have sold over $300,000 of bundles", mail.subject
    body = mail.body.encoded
    assert_includes body, "Best Selling Bundle"
    assert_includes body, "https://example.com/product1"
    assert_includes body, "$199.99"
    assert_includes body, "$99.99"
  end

  # --- #scheduled_payout_chargeback_hold -----------------------------------

  test "scheduled_payout_chargeback_hold sends notification email" do
    payout = scheduled_payouts(:chargeback_hold_scheduled_payout)
    user = payout.user
    mail = CreatorMailer.scheduled_payout_chargeback_hold(scheduled_payout_id: payout.id)

    assert_equal [user.form_email], mail.to
    assert_equal "Your payout has been delayed", mail.subject
    body = mail.body.encoded
    assert_includes body, "delayed due to a chargeback"
    assert_includes body, "contact our support team"
  end

  test "scheduled_payout_chargeback_hold returns NullMail when scheduled payout missing" do
    mail = CreatorMailer.scheduled_payout_chargeback_hold(scheduled_payout_id: 0)
    assert_kind_of ActionMailer::Base::NullMail, mail.message
  end
end
