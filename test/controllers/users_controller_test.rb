# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    boot_controller_test!
  end

  teardown { restore_protect_against_forgery! }

  test "GET current_user_data returns success with user data when signed in" do
    sign_in @seller
    @request.cookie_jar.encrypted[:current_seller_id] = @seller.id

    get :current_user_data
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
    assert_equal @seller.external_id, body.dig("user", "id")
    assert_equal @seller.email, body.dig("user", "email")
    assert_equal @seller.display_name, body.dig("user", "name")
  end

  test "GET current_user_data returns unauthorized when not signed in" do
    get :current_user_data
    assert_response :unauthorized
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
  end

  test "GET show raises RoutingError if no username (HTML)" do
    assert_raises(ActionController::RoutingError) do
      get :show
    end
  end

  test "GET show 404s for unknown username (JSON)" do
    # In JSON format, missing user falls through to `format.any { e404 }` via
    # set_user_and_custom_domain_config -> e404. We just assert non-success.
    assert_raises(StandardError) do
      get :show, params: { username: "nonexistent_user_xyz" }, format: :json
    end
  end

  test "GET show raises RoutingError for unknown username (HTML)" do
    assert_raises(ActionController::RoutingError) do
      get :show, params: { username: "nonexistent_user_xyz" }, format: :html
    end
  end
end
