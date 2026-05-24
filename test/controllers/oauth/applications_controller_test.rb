# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Oauth::ApplicationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    [@seller, @admin].each { |u| u.save(validate: false) if u.external_id.blank? }
    sign_in_as_seller(@admin, @seller)
  end

  teardown { restore_protect_against_forgery! }

  test "GET index redirects to settings_advanced_path" do
    get :index
    assert_redirected_to settings_advanced_path
  end

  test "GET new redirects to settings_advanced_path" do
    get :new
    assert_redirected_to settings_advanced_path
  end

  test "POST create creates a new application and redirects to edit" do
    assert_difference -> { @seller.oauth_applications.count }, 1 do
      post :create, params: { oauth_application: { name: "appname", redirect_uri: "http://hi" } }
    end
    app = OauthApplication.last
    assert_redirected_to edit_oauth_application_path(app.external_id)
    assert_equal "Application created.", flash[:notice]
  end

  test "POST create creates a new application with no affiliate_basis_points" do
    assert_difference -> { OauthApplication.count }, 1 do
      post :create, params: { oauth_application: { name: "appname2", redirect_uri: "http://hi" } }
    end
    assert_nil OauthApplication.last.affiliate_basis_points
  end

  test "GET show redirects to edit_oauth_application_path" do
    app = OauthApplication.create!(name: "showtest", redirect_uri: "https://example.com", owner: @seller, scopes: "edit_products")
    get :show, params: { id: app.external_id }
    assert_redirected_to edit_oauth_application_path(app.external_id)
  end

  test "DELETE destroy marks the application as deleted and redirects" do
    app = OauthApplication.create!(name: "deltest", redirect_uri: "https://example.com", owner: @seller, scopes: "edit_products")
    delete :destroy, params: { id: app.external_id }
    assert_redirected_to settings_advanced_path
    assert_equal "Application deleted.", flash[:notice]
    assert app.reload.deleted_at.present?
  end
end
