# frozen_string_literal: true

require "test_helper"

class Admin::Compliance::CardsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  tests Admin::Compliance::CardsController

  setup do
    @admin = users(:admin_user)
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
    RefundPurchaseWorker.clear
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Compliance::CardsController.ancestors, Admin::BaseController
  end

  test "POST refund returns error when stripe_fingerprint is blank" do
    post :refund, format: :json
    assert_equal false, response.parsed_body["success"]
  end


  test "POST refund enqueues jobs for matching successful purchases" do
    fingerprint = "TestFingerprintC1"
    seller = users(:named_seller)
    product = links(:named_seller_product)

    successful = build_purchase(stripe_fingerprint: fingerprint, purchase_state: "successful", seller: seller, link: product)
    build_purchase(stripe_fingerprint: fingerprint, purchase_state: "failed", seller: seller, link: product)
    build_purchase(stripe_fingerprint: fingerprint, purchase_state: "successful", chargeback_date: Time.current, seller: seller, link: product)

    post :refund, params: { stripe_fingerprint: fingerprint }, format: :json

    assert_equal true, response.parsed_body["success"]
    assert_equal 1, RefundPurchaseWorker.jobs.size
    job = RefundPurchaseWorker.jobs.first
    assert_equal successful.id, job["args"][0]
    assert_equal @admin.id, job["args"][1]
    assert_equal Refund::FRAUD, job["args"][2]
  end

  test "POST refund only refunds purchases from the last 6 months" do
    fingerprint = "TestFingerprintC2"
    seller = users(:named_seller)
    product = links(:named_seller_product)

    recent_p1 = build_purchase(stripe_fingerprint: fingerprint, purchase_state: "successful", seller: seller, link: product)
    recent_p2 = build_purchase(stripe_fingerprint: fingerprint, purchase_state: "successful", created_at: 5.months.ago, seller: seller, link: product)
    build_purchase(stripe_fingerprint: fingerprint, purchase_state: "successful", created_at: 7.months.ago, seller: seller, link: product)

    post :refund, params: { stripe_fingerprint: fingerprint }, format: :json

    assert_equal 2, RefundPurchaseWorker.jobs.size
    ids = RefundPurchaseWorker.jobs.map { |j| j["args"][0] }.sort
    assert_equal [recent_p1.id, recent_p2.id].sort, ids
  end

  private
    # Bypass heavy validations and product_is_not_blocked callback by inserting raw.
    def build_purchase(**attrs)
      p = Purchase.new(
        link: attrs[:link] || links(:named_seller_product),
        seller: attrs[:seller] || users(:named_seller),
        email: "x@example.com",
        purchase_state: attrs[:purchase_state] || "successful",
        price_cents: 1500,
        total_transaction_cents: 1500,
        displayed_price_cents: 1500,
        displayed_price_currency_type: "usd",
        stripe_fingerprint: attrs[:stripe_fingerprint],
        chargeback_date: attrs[:chargeback_date]
      )
      p.created_at = attrs[:created_at] if attrs[:created_at]
      p.save!(validate: false)
      p
    end
end
