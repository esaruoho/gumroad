# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Products::AffiliatedControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    sign_in_as_seller(@seller)
    @request.headers["X-Inertia"] = "true"
  end

  teardown { restore_protect_against_forgery! }

  test "GET index renders the Products/Affiliated/Index inertia component" do
    get :index
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Products/Affiliated/Index", page["component"]
  end

  test "GET index returns JSON props when requested as JSON" do
    @request.headers["X-Inertia"] = nil
    get :index, format: :json
    assert_response :success
    body = JSON.parse(@response.body)
    assert_kind_of Hash, body
  end

  test "GET index redirects when not signed in" do
    sign_out @seller
    get :index
    assert_response :redirect
  end
end
