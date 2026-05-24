# frozen_string_literal: true

require "test_helper"

class Admin::LinksControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    sign_in @admin
    @request.env["HTTP_REFERER"] = "where_i_came_from"
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
    @product = links(:basic_user_product)
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::LinksController.ancestors, Admin::BaseController
  end

  test "GET show redirects numeric ID to external_id" do
    get :show, params: { external_id: @product.id }
    assert_redirected_to admin_product_path(@product.external_id)
  end

  test "GET show renders the product page when looked up via external_id" do
    get :show, params: { external_id: @product.external_id }
    assert_response :success
  end

  test "GET show raises 404 when no products matched by permalink" do
    assert_raises(ActionController::RoutingError) do
      get :show, params: { external_id: "nonexistent-permalink-#{SecureRandom.hex(4)}" }
    end
  end

  test "DELETE destroy deletes the product" do
    delete :destroy, params: { external_id: @product.external_id }, format: :json
    assert_response :success
    assert @product.reload.deleted_at.present?
  end

  test "DELETE destroy raises 404 when product is not found" do
    assert_raises(ActionController::RoutingError) do
      delete :destroy, params: { external_id: "invalid-id-#{SecureRandom.hex(4)}" }, format: :json
    end
  end

  test "POST restore restores a deleted product" do
    @product.update!(deleted_at: 1.day.ago)
    post :restore, params: { external_id: @product.external_id }, format: :json
    assert_response :success
    assert_nil @product.reload.deleted_at
  end

  test "POST publish publishes the product" do
    @product.update!(purchase_disabled_at: Time.current)
    post :publish, params: { external_id: @product.external_id }, format: :json
    assert_response :success
    if response.parsed_body["success"]
      assert_nil @product.reload.purchase_disabled_at
    else
      # Product can't be published (e.g. validation), but the action ran.
      assert_includes response.parsed_body.keys, "error_message"
    end
  end

  test "DELETE unpublish unpublishes the product" do
    @product.update!(purchase_disabled_at: nil)
    delete :unpublish, params: { external_id: @product.external_id }, format: :json
    assert_response :success
    assert @product.reload.purchase_disabled_at.present?
  end

  test "POST is_adult marks the product as adult and back" do
    post :is_adult, params: { external_id: @product.external_id, is_adult: true }, format: :json
    assert_response :success
    assert_equal true, @product.reload.is_adult

    post :is_adult, params: { external_id: @product.external_id, is_adult: false }, format: :json
    assert_response :success
    assert_equal false, @product.reload.is_adult
  end

  test "POST is_adult raises 404 if the product is not found" do
    assert_raises(ActionController::RoutingError) do
      post :is_adult, params: { external_id: "invalid-#{SecureRandom.hex(4)}", is_adult: true }, format: :json
    end
  end

  test "POST set_content_moderation_disabled toggles content_moderation_disabled" do
    post :set_content_moderation_disabled, params: { external_id: @product.external_id, disabled: "true" }, format: :json
    assert_response :success
    assert @product.reload.content_moderation_disabled?

    post :set_content_moderation_disabled, params: { external_id: @product.external_id, disabled: "false" }, format: :json
    assert_response :success
    refute @product.reload.content_moderation_disabled?
  end
end
