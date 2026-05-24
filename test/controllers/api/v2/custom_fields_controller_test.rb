# frozen_string_literal: true

require "test_helper"

class Api::V2::CustomFieldsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:basic_user)
    @user.save! if @user.external_id.blank?
    @product = links(:basic_user_product)

    @app_owner = users(:purchaser)
    @app_owner.save! if @app_owner.external_id.blank?

    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com",
      owner: @app_owner,
      scopes: "edit_products view_sales mark_sales_as_shipped edit_sales view_public account"
    )

    @custom_fields = [
      CustomField.create!(name: "country", required: true, field_type: CustomField::TYPE_TEXT, seller: @user, products: [@product]),
      CustomField.create!(name: "zip", required: true, field_type: CustomField::TYPE_TEXT, seller: @user, products: [@product])
    ]
  end

  test "GET index returns 401 without token" do
    get :index, params: { link_id: @product.external_id }
    assert_response :unauthorized
  end

  test "GET index returns the custom fields with view_public scope" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "view_public")
    get :index, params: { link_id: @product.external_id, access_token: token.token }
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    names = body["custom_fields"].map { |f| f["name"] }.sort
    assert_equal %w[country zip], names
  end

  test "GET index grants access with the account scope" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "account")
    get :index, params: { link_id: @product.external_id, access_token: token.token }
    assert_response :success
    assert_equal true, response.parsed_body["success"]
  end

  test "POST create with edit_products scope creates a new custom field" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "edit_products")
    assert_difference "@user.custom_fields.count", 1 do
      post :create, params: { link_id: @product.external_id, name: "phone", required: "true", access_token: token.token }
    end
    assert_response :success
    assert_equal true, response.parsed_body["success"]
  end

  test "DELETE destroy with edit_products removes the custom field association" do
    token = Doorkeeper::AccessToken.create!(application: @oauth_app, resource_owner_id: @user.id, scopes: "edit_products")
    field = @custom_fields.first
    delete :destroy, params: { link_id: @product.external_id, id: field.name, access_token: token.token }
    assert_response :success
    assert_equal true, response.parsed_body["success"]
  end
end
