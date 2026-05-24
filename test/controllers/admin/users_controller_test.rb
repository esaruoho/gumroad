# frozen_string_literal: true

require "test_helper"

class Admin::UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    @user = users(:named_seller)
    @user.save! if @user.external_id.blank?
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
    WebMock.stub_request(:get, %r{api\.pwnedpasswords\.com/range/.*}).to_return(status: 200, body: "")
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::UsersController.ancestors, Admin::BaseController
  end

  test "GET show returns the user as JSON" do
    get :show, params: { external_id: @user.external_id }, format: :json
    assert_response :success
    assert_kind_of Hash, response.parsed_body
  end

  test "POST refund_balance enqueues RefundUnpaidPurchasesWorker" do
    Sidekiq::Testing.fake! do
      assert_difference -> { RefundUnpaidPurchasesWorker.jobs.size }, 1 do
        post :refund_balance, params: { external_id: @user.external_id }
      end
    end
    assert_response :success
    assert_equal true, response.parsed_body["success"]
  end

  test "POST reset_password updates the user's password and returns the new value" do
    old_digest = @user.encrypted_password
    post :reset_password, params: { external_id: @user.external_id }
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert_match(/New password is/, body["message"])
    refute_equal old_digest, @user.reload.encrypted_password
  end

  test "POST confirm_email confirms the user" do
    @user.update_columns(confirmed_at: nil)
    post :confirm_email, params: { external_id: @user.external_id }
    assert_response :success
    assert_equal true, response.parsed_body["success"]
    assert_not_nil @user.reload.confirmed_at
  end

  test "POST disable_paypal_sales sets the flag" do
    post :disable_paypal_sales, params: { external_id: @user.external_id }
    assert_response :success
    assert_equal true, response.parsed_body["success"]
    assert_equal true, @user.reload.disable_paypal_sales?
  end

  test "POST update_email with blank email returns nil (no render)" do
    post :update_email, params: { external_id: @user.external_id, update_email: { email_address: "" } }
    # Controller returns without rendering; default empty body is fine.
    assert_response :no_content
  end

  test "POST update_email updates email when valid" do
    post :update_email, params: { external_id: @user.external_id, update_email: { email_address: "newemail+ctrl@example.com" } }
    assert_response :success
    assert_equal "newemail+ctrl@example.com", @user.reload.unconfirmed_email.presence || @user.email
  end
end
