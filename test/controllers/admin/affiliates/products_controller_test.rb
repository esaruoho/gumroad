# frozen_string_literal: true

require "test_helper"

class Admin::Affiliates::ProductsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }

    @seller = users(:referrer_user)
    @seller.save! if @seller.external_id.blank?
    @affiliate_user = users(:bvi_test_seller) # isolated user, no fixture affiliations
    @affiliate_user.save! if @affiliate_user.external_id.blank?

    @published = Link.new(user: @seller, name: "Published product", price_cents: 100)
    @published.save!
    @unpublished = Link.new(user: @seller, name: "Unpublished product", price_cents: 100, purchase_disabled_at: Time.current)
    @unpublished.save!
    @deleted = Link.new(user: @seller, name: "Deleted product", price_cents: 100, deleted_at: Time.current)
    @deleted.save!

    @alive_affiliate = DirectAffiliate.create!(
      seller: @seller,
      affiliate_user: @affiliate_user,
      affiliate_basis_points: 1000,
    )
    [@published, @unpublished, @deleted].each do |p|
      @alive_affiliate.products << p
    end
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Affiliates::ProductsController.ancestors, Admin::BaseController
  end

  test "GET index returns successful response with Inertia page data" do
    get :index, params: { affiliate_external_id: @affiliate_user.external_id }
    assert_response :success
    page = JSON.parse(CGI.unescapeHTML(@response.body.match(/data-page="([^"]*)"/)[1]))
    assert_equal "Admin/Affiliates/Products/Index", page["component"]
    external_ids = page["props"]["products"].map { _1["external_id"] }
    # The controller .unscope(:purchase_disabled_at) — published + unpublished, no deleted.
    assert_includes external_ids, @published.external_id
    assert_includes external_ids, @unpublished.external_id
    refute_includes external_ids, @deleted.external_id
    assert_equal({ "pages" => 1, "page" => 1 }, page["props"]["pagination"])
  end
end
