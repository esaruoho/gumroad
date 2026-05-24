# frozen_string_literal: true

require "test_helper"

class Admin::MerchantAccountPresenterTest < ActiveSupport::TestCase
  setup do
    @merchant_account = merchant_accounts(:forfeit_user_stripe_account)
  end

  def fake_stripe_account(charges_enabled: false, payouts_enabled: false, disabled_reason: "rejected.fraud", requirements_json: {})
    requirements = Struct.new(:disabled_reason, :as_json_value).new(disabled_reason, requirements_json)
    requirements.define_singleton_method(:as_json) { as_json_value }
    Struct.new(:charges_enabled, :payouts_enabled, :requirements).new(
      charges_enabled, payouts_enabled, requirements
    )
  end

  test "#props returns the expected field shape for Stripe merchant accounts" do
    fake = fake_stripe_account
    Stripe::Account.stub(:retrieve, ->(_) { fake }) do
      props = Admin::MerchantAccountPresenter.new(merchant_account: @merchant_account).props

      assert_equal @merchant_account.charge_processor_id, props[:charge_processor_id]
      assert_equal @merchant_account.charge_processor_merchant_id, props[:charge_processor_merchant_id]
      assert_equal @merchant_account.external_id, props[:external_id]
      assert_equal @merchant_account.user.external_id, props[:user_external_id]
      assert_equal @merchant_account.country, props[:country]
      assert_equal "United States", props[:country_name]
      assert_equal @merchant_account.currency, props[:currency]
      assert_equal @merchant_account.holder_of_funds, props[:holder_of_funds]
      assert_includes props[:stripe_account_url], "dashboard.stripe.com"
      assert_equal @merchant_account.created_at, props[:created_at]
      assert_equal @merchant_account.updated_at, props[:updated_at]
      assert_includes props[:live_attributes], { label: "Charges enabled", value: false }
    end
  end

  test "#props returns the country name from ISO3166" do
    @merchant_account.update!(country: "US")
    Stripe::Account.stub(:retrieve, ->(_) { fake_stripe_account }) do
      props = Admin::MerchantAccountPresenter.new(merchant_account: @merchant_account).props
      assert_equal "US", props[:country]
      assert_equal "United States", props[:country_name]
    end
  end

  test "#props returns nil for country_name when country is blank" do
    @merchant_account.update!(country: nil)
    Stripe::Account.stub(:retrieve, ->(_) { fake_stripe_account }) do
      props = Admin::MerchantAccountPresenter.new(merchant_account: @merchant_account).props
      assert_nil props[:country]
      assert_nil props[:country_name]
    end
  end

  test "#props returns a Stripe account URL for Stripe merchant accounts" do
    @merchant_account.update!(charge_processor_merchant_id: "acct_test123")
    Stripe::Account.stub(:retrieve, ->(_) { fake_stripe_account }) do
      props = Admin::MerchantAccountPresenter.new(merchant_account: @merchant_account).props
      assert_includes props[:stripe_account_url], "acct_test123"
    end
  end

  test "#props returns nil for stripe_account_url for PayPal merchant accounts" do
    paypal = merchant_accounts(:forfeit_gumroad_paypal_account)
    paypal.define_singleton_method(:paypal_account_details) { nil }
    props = Admin::MerchantAccountPresenter.new(merchant_account: paypal).props
    assert_nil props[:stripe_account_url]
  end

  test "#props returns the correct live_attributes for Stripe accounts" do
    fake = fake_stripe_account(
      charges_enabled: false, payouts_enabled: false, disabled_reason: "rejected.fraud",
      requirements_json: { "pending_verification" => ["business_profile.url"] }
    )
    Stripe::Account.stub(:retrieve, ->(_) { fake }) do
      props = Admin::MerchantAccountPresenter.new(merchant_account: @merchant_account).props
      assert_includes props[:live_attributes], { label: "Charges enabled", value: false }
      assert_includes props[:live_attributes], { label: "Payout enabled", value: false }
      assert_includes props[:live_attributes], { label: "Disabled reason", value: "rejected.fraud" }
      fields_needed = props[:live_attributes].find { |a| a[:label] == "Fields needed" }
      assert_equal({ "pending_verification" => ["business_profile.url"] }, fields_needed[:value])
    end
  end

  test "#props returns an error message when Stripe access is revoked" do
    Stripe::Account.stub(:retrieve, ->(_) { raise Stripe::PermissionError.new("no access") }) do
      props = Admin::MerchantAccountPresenter.new(merchant_account: @merchant_account).props
      assert_equal(
        [{ label: "Error", value: "Stripe account access has been revoked or the account no longer exists" }],
        props[:live_attributes]
      )
    end
  end

  test "#props returns PayPal email in live_attributes when present" do
    paypal = merchant_accounts(:forfeit_gumroad_paypal_account)
    paypal.update!(user_id: users(:basic_user).id)
    paypal.define_singleton_method(:paypal_account_details) { { "primary_email" => "seller@example.com" } }
    props = Admin::MerchantAccountPresenter.new(merchant_account: paypal).props
    assert_equal [{ label: "Email", value: "seller@example.com" }], props[:live_attributes]
  end

  test "#props returns an empty array for live_attributes when PayPal details unavailable" do
    paypal = merchant_accounts(:forfeit_gumroad_paypal_account)
    paypal.update!(user_id: users(:basic_user).id)
    paypal.define_singleton_method(:paypal_account_details) { nil }
    props = Admin::MerchantAccountPresenter.new(merchant_account: paypal).props
    assert_equal [], props[:live_attributes]
  end
end
