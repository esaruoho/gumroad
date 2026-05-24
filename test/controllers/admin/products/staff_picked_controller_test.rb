# frozen_string_literal: true

require "test_helper"

class Admin::Products::StaffPickedControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
    @product = links(:basic_user_product)
    # Make product recommendable
    Link.define_method(:recommendable?) { true }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
    Link.remove_method(:recommendable?) if Link.instance_methods(false).include?(:recommendable?)
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Products::StaffPickedController.ancestors, Admin::BaseController
  end

  test "POST create with no existing staff_picked_product creates a record" do
    assert_nil @product.staff_picked_product
    assert_difference "StaffPickedProduct.count", 1 do
      post :create, params: { product_external_id: @product.external_id }, format: :json
    end
    assert_response :success
    assert @product.reload.staff_picked?
  end

  test "POST create with a deleted staff_picked_product undeletes it" do
    @product.create_staff_picked_product!(deleted_at: Time.current)
    post :create, params: { product_external_id: @product.external_id }, format: :json
    assert_response :success
    assert @product.reload.staff_picked?
  end
end
