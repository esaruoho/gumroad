# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class CommunitiesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    @community = communities(:named_seller_product_community)
    @request.headers["X-Inertia"] = "true"
    sign_in_as_seller(@seller, @seller)
    Feature.activate_user(:communities, @seller)
  end

  teardown do
    Feature.deactivate_user(:communities, @seller)
    restore_protect_against_forgery!
  end

  test "GET index redirects to first community" do
    get :index
    assert_redirected_to community_path(@community.seller.external_id, @community.external_id)
  end

  test "GET index redirects to dashboard when no communities exist" do
    Community.where(seller: @seller).destroy_all
    get :index
    assert_redirected_to dashboard_path
    assert_equal "You are not allowed to perform this action.", flash[:alert]
  end

  test "GET index redirects to dashboard when :communities feature is disabled" do
    Feature.deactivate_user(:communities, @seller)
    get :index
    assert_redirected_to dashboard_path
    assert_equal "You are not allowed to perform this action.", flash[:alert]
  end
end
