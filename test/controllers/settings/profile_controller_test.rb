# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Settings::ProfileControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    sign_in_as_seller(@admin, @seller)
  end

  teardown { restore_protect_against_forgery! }

  test "GET show returns success and renders Settings/Profile/Show" do
    get :show
    assert_response :success
    page = JSON.parse(CGI.unescapeHTML(@response.body.match(/data-page="([^"]*)"/)[1]))
    assert_equal "Settings/Profile/Show", page["component"]
    assert page["props"].present?
  end
end
