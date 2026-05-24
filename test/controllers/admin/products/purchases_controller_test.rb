# frozen_string_literal: true

require "test_helper"

class Admin::Products::PurchasesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
    @product = links(:basic_user_product)
    @seller = @product.user
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Products::PurchasesController.ancestors, Admin::BaseController
  end

  test "GET index returns purchases and pagination" do
    p = build_purchase(link: @product, seller: @seller, purchase_state: "successful")
    get :index, params: { product_external_id: @product.external_id }, format: :json
    assert_response :ok
    body = response.parsed_body
    ids = body["purchases"].map { |x| x["external_id"] }
    assert_includes ids, p.external_id
    assert body["pagination"].present?
  end

  test "GET index returns only purchases for the specified product" do
    p_mine = build_purchase(link: @product, seller: @seller, purchase_state: "successful")
    other_product = links(:named_seller_product)
    p_other = build_purchase(link: other_product, seller: other_product.user, purchase_state: "successful")

    get :index, params: { product_external_id: @product.external_id }, format: :json
    ids = response.parsed_body["purchases"].map { |x| x["external_id"] }
    assert_includes ids, p_mine.external_id
    refute_includes ids, p_other.external_id
  end

  test "POST mass_refund_for_fraud requires purchase ids" do
    post :mass_refund_for_fraud, params: { product_external_id: @product.external_id, purchase_ids: [] }, as: :json
    assert_response :unprocessable_entity
    assert_equal false, response.parsed_body["success"]
  end

  test "POST mass_refund_for_fraud rejects purchases not belonging to the product" do
    other_product = links(:named_seller_product)
    other = build_purchase(link: other_product, seller: other_product.user, purchase_state: "successful")
    post :mass_refund_for_fraud,
         params: { product_external_id: @product.external_id, purchase_ids: [other.external_id] },
         format: :json
    assert_response :unprocessable_entity
    assert_equal false, response.parsed_body["success"]
  end

  test "POST mass_refund_for_fraud enqueues the job with correct parameters" do
    p1 = build_purchase(link: @product, seller: @seller, purchase_state: "successful")
    p2 = build_purchase(link: @product, seller: @seller, purchase_state: "failed")
    MassRefundForFraudJob.clear

    post :mass_refund_for_fraud,
         params: { product_external_id: @product.external_id, purchase_ids: [p1.external_id, p2.external_id] },
         format: :json

    assert_response :ok
    assert_equal true, response.parsed_body["success"]
    assert_includes response.parsed_body["message"], "Processing 2 fraud refunds"
    assert_equal 1, MassRefundForFraudJob.jobs.size
    job = MassRefundForFraudJob.jobs.first
    assert_equal @product.id, job["args"][0]
    assert_equal [p1.external_id, p2.external_id], job["args"][1]
    assert_equal @admin.id, job["args"][2]
  end

  private
    def build_purchase(link:, seller:, purchase_state: "successful")
      p = Purchase.new(
        link: link, seller: seller, email: "buyer-#{SecureRandom.hex(4)}@example.com",
        purchase_state: purchase_state, price_cents: 1500, total_transaction_cents: 1500,
        displayed_price_cents: 1500, displayed_price_currency_type: "usd"
      )
      p.save!(validate: false)
      p
    end
end
