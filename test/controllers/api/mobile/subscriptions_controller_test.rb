# frozen_string_literal: true

require "test_helper"

class Api::Mobile::SubscriptionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @valid_token = Api::Mobile::BaseController::MOBILE_TOKEN
  end

  test "GET subscription_attributes returns 401 with invalid mobile token" do
    get :subscription_attributes, params: { id: "x", mobile_token: "bad" }
    assert_response :unauthorized
  end

  test "GET subscription_attributes returns success false for unknown subscription" do
    get :subscription_attributes, params: { id: "no-such-#{SecureRandom.hex(4)}", mobile_token: @valid_token }
    body = response.parsed_body
    assert_equal false, body["success"]
  end
end
