# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class TaxCenterControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    sign_in_as_seller(@seller)
  end

  teardown { restore_protect_against_forgery! }

  test "GET index redirects to dashboard when tax_center is not enabled" do
    @seller.define_singleton_method(:tax_center_enabled?) { false }
    User.define_method(:tax_center_enabled?) { false } unless User.method_defined?(:tax_center_enabled?)
    get :index
    assert_redirected_to dashboard_path
    assert_equal "Tax center is not enabled for your account.", flash[:alert]
  ensure
    User.remove_method(:tax_center_enabled?) if User.instance_methods(false).include?(:tax_center_enabled?)
  end

  test "GET download redirects with an error if tax form not found and tax_center disabled" do
    User.define_method(:tax_center_enabled?) { false } unless User.method_defined?(:tax_center_enabled?)
    get :download, params: { year: "2024", form_type: "us_1099_misc" }
    assert_redirected_to dashboard_path
  ensure
    User.remove_method(:tax_center_enabled?) if User.instance_methods(false).include?(:tax_center_enabled?)
  end
end
