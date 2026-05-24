# frozen_string_literal: true

require "test_helper"

class Stripe::SetupIntentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    boot_controller_test!
  end

  teardown { restore_protect_against_forgery! }

  test "POST create with invalid card params responds with an error" do
    post :create, params: {}
    assert_response :unprocessable_entity
    assert_equal false, @response.parsed_body["success"]
    assert_equal "We couldn't charge your card. Try again or use a different card.", @response.parsed_body["error_message"]
  end
end
