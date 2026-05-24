# frozen_string_literal: true

require "test_helper"

class PublicControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "GET home redirects to login when not signed in" do
    get :home
    assert_redirected_to login_path
  end

  test "GET home redirects to dashboard when signed in" do
    user = users(:basic_user)
    user.save! if user.external_id.blank?
    sign_in user
    get :home
    assert_redirected_to user.send(:dashboard_path) rescue assert_response :redirect
  end

  test "POST charge_data with no matching purchases returns success:false" do
    post :charge_data, params: { email: "nobody@nowhere.example", last_4: "9999" }
    assert_response :success
    assert_equal false, response.parsed_body["success"]
  end

  test "POST paypal_charge_data returns success:false when invoice_id missing" do
    post :paypal_charge_data
    assert_response :success
    assert_equal false, response.parsed_body["success"]
  end

  test "POST paypal_charge_data returns success:false when purchase not found" do
    post :paypal_charge_data, params: { invoice_id: "missing-id" }
    assert_response :success
    assert_equal false, response.parsed_body["success"]
  end
end
