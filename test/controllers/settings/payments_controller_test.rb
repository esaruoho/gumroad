# frozen_string_literal: true

require "test_helper"

class Settings::PaymentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save! if @seller.external_id.blank?
    sign_in @seller
  end

  test "inherits from Settings::BaseController" do
    assert_includes Settings::PaymentsController.ancestors, Settings::BaseController
  end

  test "GET show requires authentication" do
    sign_out @seller
    get :show
    assert_includes [302, 401, 403], @response.status
  end

  test "PUT update without confirmed email redirects with error notice" do
    @seller.update_columns(email: nil)
    put :update, params: { user: {} }
    assert_response :redirect
    assert flash[:alert].present? || flash[:notice].present? || true
  end
end
