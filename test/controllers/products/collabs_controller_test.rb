# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Products::CollabsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    sign_in_as_seller(@seller)
    @request.headers["X-Inertia"] = "true"
  end

  teardown { restore_protect_against_forgery! }

  test "GET index renders the Products/Collabs/Index inertia component" do
    get :index
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Products/Collabs/Index", page["component"]
  end

  test "GET index redirects when not signed in" do
    sign_out @seller
    get :index
    assert_response :redirect
  end
end
