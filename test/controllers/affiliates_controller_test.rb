# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class AffiliatesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    sign_in_as_seller(@admin, @seller)
    @request.headers["X-Inertia"] = "true"
  end

  teardown { restore_protect_against_forgery! }

  test "GET index renders the affiliates inertia component" do
    get :index
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Affiliates/Index", page["component"]
    assert page["props"]["affiliates"].present?
  end

  test "GET new renders the new inertia component" do
    get :new
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Affiliates/New", page["component"]
    assert_kind_of Array, page["props"]["products"]
  end

  test "GET edit returns 404 for non-existent affiliate" do
    assert_raises(ActionController::RoutingError) do
      get :edit, params: { id: "nonexistent" }
    end
  end
end
