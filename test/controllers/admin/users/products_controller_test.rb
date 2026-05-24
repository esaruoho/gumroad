# frozen_string_literal: true

require "test_helper"

class Admin::Users::ProductsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
    # Isolate to a user with no fixture products so price-cents stubs aren't needed.
    @user = users(:referrer_user)
    @user.save! if @user.external_id.blank?
    @product = Link.new(user: @user, name: "Admin Products Test", price_cents: 100)
    @product.save!
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Users::ProductsController.ancestors, Admin::BaseController
  end

  def page_props
    page = JSON.parse(CGI.unescapeHTML(@response.body.match(/data-page="([^"]*)"/)[1]))
    page["props"]
  end

  test "GET index returns successful response with Inertia page data" do
    get :index, params: { user_external_id: @user.external_id }
    assert_response :success
    page = JSON.parse(CGI.unescapeHTML(@response.body.match(/data-page="([^"]*)"/)[1]))
    assert_equal "Admin/Users/Products/Index", page["component"]
    external_ids = page["props"]["products"].map { _1["external_id"] }
    assert_equal [@product.external_id], external_ids
    assert_equal({ "pages" => 1, "page" => 1 }, page["props"]["pagination"])
  end

  test "GET index includes deleted products" do
    @product.update!(deleted_at: Time.current)
    get :index, params: { user_external_id: @user.external_id }
    assert_response :success
    assert_includes page_props["products"].map { _1["external_id"] }, @product.external_id
  end

  test "GET index includes banned products" do
    @product.update!(banned_at: Time.current)
    get :index, params: { user_external_id: @user.external_id }
    assert_response :success
    assert_includes page_props["products"].map { _1["external_id"] }, @product.external_id
  end
end
