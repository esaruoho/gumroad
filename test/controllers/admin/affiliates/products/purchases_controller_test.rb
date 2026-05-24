# frozen_string_literal: true

require "test_helper"

class Admin::Affiliates::Products::PurchasesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }

    @product = links(:named_seller_product)
    @seller = users(:named_seller)
    @affiliate_user = users(:another_seller)
    @affiliate = affiliates(:aff_credit_test_direct_affiliate_all_products)
    @affiliate_user.save! if @affiliate_user.external_id.blank?
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Affiliates::Products::PurchasesController.ancestors, Admin::BaseController
  end

  test "GET index returns purchases and pagination for the affiliate" do
    p = build_purchase(link: @product, seller: @seller, affiliate: @affiliate, purchase_state: "successful")
    get :index, params: { product_external_id: @product.external_id, affiliate_external_id: @affiliate_user.external_id }, format: :json
    assert_response :ok
    body = response.parsed_body
    ids = body["purchases"].map { |x| x["external_id"] }
    assert_includes ids, p.external_id
    assert body["pagination"].present?
  end

  test "GET index returns only purchases for the affiliate user" do
    p_aff = build_purchase(link: @product, seller: @seller, affiliate: @affiliate, purchase_state: "successful")
    p_no_aff = build_purchase(link: @product, seller: @seller, affiliate: nil, purchase_state: "successful")

    get :index, params: { product_external_id: @product.external_id, affiliate_external_id: @affiliate_user.external_id }, format: :json
    ids = response.parsed_body["purchases"].map { |x| x["external_id"] }
    assert_includes ids, p_aff.external_id
    refute_includes ids, p_no_aff.external_id
  end

  private
    def build_purchase(link:, seller:, affiliate:, purchase_state: "successful")
      p = Purchase.new(
        link: link, seller: seller, email: "buyer-#{SecureRandom.hex(4)}@example.com",
        purchase_state: purchase_state, price_cents: 1500, total_transaction_cents: 1500,
        displayed_price_cents: 1500, displayed_price_currency_type: "usd",
        affiliate: affiliate
      )
      p.save!(validate: false)
      p
    end
end
