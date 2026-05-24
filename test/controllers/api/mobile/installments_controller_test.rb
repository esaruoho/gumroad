# frozen_string_literal: true

require "test_helper"

class Api::Mobile::InstallmentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @mobile_token = Api::Mobile::BaseController::MOBILE_TOKEN
  end

  test "GET show returns 401 with invalid mobile token" do
    get :show, params: { id: "xxx", mobile_token: "bad" }
    assert_response :unauthorized
  end

  test "GET show returns 404 when installment is not found" do
    get :show, params: { id: "nope-#{SecureRandom.hex(4)}", mobile_token: @mobile_token }
    assert_response :not_found
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_equal "Could not find installment", body["message"]
  end

  test "GET show returns 404 when no related object is provided" do
    inst = installments(:published_post)
    get :show, params: { id: inst.external_id, mobile_token: @mobile_token }
    assert_response :not_found
    assert_equal "Could not find related object to the installment.", response.parsed_body["message"]
  end
end
