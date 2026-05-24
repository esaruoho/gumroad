# frozen_string_literal: true

require "test_helper"

class Admin::Search::PurchasesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
    @orig_radar = Radar::ChargeRiskLevelService.method(:fetch_bulk)
    Radar::ChargeRiskLevelService.define_singleton_method(:fetch_bulk) { |_| {} }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
    Radar::ChargeRiskLevelService.define_singleton_method(:fetch_bulk, @orig_radar) if @orig_radar
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Search::PurchasesController.ancestors, Admin::BaseController
  end

  test "GET index returns successful HTML response" do
    get :index, params: { query: "no-such-email-#{SecureRandom.hex(4)}@example.com" }
    assert_response :success
  end

  test "GET index returns JSON response when requested" do
    email = "find-me-#{SecureRandom.hex(4)}@example.com"
    p1 = build_purchase(email: email, created_at: 3.seconds.ago)
    p2 = build_purchase(email: email, created_at: 2.seconds.ago)
    p3 = build_purchase(email: email, created_at: 1.second.ago)

    get :index, params: { query: email, per_page: 2 }, format: :json
    assert_response :success
    assert_match %r{application/json}, response.content_type
    ids = response.parsed_body["purchases"].map { |x| x["external_id"] }
    assert_includes ids, p3.external_id
    assert_includes ids, p2.external_id
    refute_includes ids, p1.external_id
    assert response.parsed_body["pagination"].present?
  end

  private
    def build_purchase(email:, created_at:)
      p = Purchase.new(
        link: links(:basic_user_product), seller: links(:basic_user_product).user,
        email: email, purchase_state: "successful",
        price_cents: 1500, total_transaction_cents: 1500,
        displayed_price_cents: 1500, displayed_price_currency_type: "usd",
        gumroad_tax_cents: 0, fee_cents: 0, tax_cents: 0
      )
      p.created_at = created_at
      p.save!(validate: false)
      p
    end
end
