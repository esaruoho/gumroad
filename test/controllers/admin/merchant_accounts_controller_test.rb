# frozen_string_literal: true

require "test_helper"

class Admin::MerchantAccountsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
    @merchant_account = merchant_accounts(:radar_stripe_connect_account)

    # Stub Stripe::Account.retrieve to avoid real network calls.
    @stripe_acct = Struct.new(:charges_enabled, :payouts_enabled, :requirements).new(
      true, true,
      Struct.new(:disabled_reason, :as_json_value).new(nil, {}).tap do |r|
        r.define_singleton_method(:as_json) { r.as_json_value }
      end
    )
    @orig_retrieve = Stripe::Account.method(:retrieve)
    fake = @stripe_acct
    Stripe::Account.define_singleton_method(:retrieve) { |*_a, **_k| fake }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
    Stripe::Account.define_singleton_method(:retrieve, @orig_retrieve) if @orig_retrieve
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::MerchantAccountsController.ancestors, Admin::BaseController
  end

  test "GET show redirects numeric ID to external_id" do
    get :show, params: { external_id: @merchant_account.id }
    assert_redirected_to admin_merchant_account_path(@merchant_account.external_id)
  end

  test "GET show renders the page successfully with external_id" do
    get :show, params: { external_id: @merchant_account.external_id }
    assert_response :success
  end

  test "GET show renders the page successfully with charge_processor_merchant_id" do
    get :show, params: { external_id: @merchant_account.charge_processor_merchant_id }
    assert_response :success
  end
end
