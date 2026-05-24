# frozen_string_literal: true

require "test_helper"

class Admin::Users::PayoutsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    @user = users(:named_seller)
    @user.save! if @user.external_id.blank?
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Users::PayoutsController.ancestors, Admin::BaseController
  end

  test "GET index renders payouts page" do
    get :index, params: { user_external_id: @user.external_id }
    assert_response :success
  end

  test "POST pause flips payouts_paused_internally and creates a payouts-paused comment when reason present" do
    assert_changes -> { @user.reload.payouts_paused_internally? }, from: false, to: true do
      assert_difference -> { @user.comments.where(comment_type: Comment::COMMENT_TYPE_PAYOUTS_PAUSED).count } do
        post :pause, params: { user_external_id: @user.external_id, pause_payouts: { reason: "fraud check" } }, format: :json
      end
    end
    assert_response :success
    assert_equal true, response.parsed_body["success"]
    assert_equal @admin.id, @user.reload.payouts_paused_by
  end

  test "POST pause without reason does not create a comment" do
    assert_no_difference -> { @user.comments.count } do
      post :pause, params: { user_external_id: @user.external_id, pause_payouts: { reason: "" } }, format: :json
    end
    assert_response :success
    assert @user.reload.payouts_paused_internally?
  end

  test "POST resume returns success:false when payouts are not paused" do
    refute @user.payouts_paused_internally?
    post :resume, params: { user_external_id: @user.external_id }, format: :json
    assert_response :success
    assert_equal false, response.parsed_body["success"]
  end

  test "POST resume clears paused flag and posts a resumed comment" do
    @user.update!(payouts_paused_internally: true, payouts_paused_by: @admin.id)
    assert_difference -> { @user.comments.where(comment_type: Comment::COMMENT_TYPE_PAYOUTS_RESUMED).count } do
      post :resume, params: { user_external_id: @user.external_id }, format: :json
    end
    assert_response :success
    assert_equal true, response.parsed_body["success"]
    refute @user.reload.payouts_paused_internally?
    assert_nil @user.payouts_paused_by
  end
end
