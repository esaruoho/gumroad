# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class ImportedCustomersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    @product = links(:named_seller_product)
    sign_in_as_seller(@admin, @seller)
  end

  teardown { restore_protect_against_forgery! }

  test "GET index returns the correct number of imported customers on first page" do
    25.times do |i|
      ImportedCustomer.create!(email: "ic-#{i}@example.com", purchase_date: Time.current, link_id: @product.id, importing_user: @seller)
    end
    get :index, params: { link_id: @product.unique_permalink, page: 0 }
    body = JSON.parse(@response.body)
    assert_equal 20, body["customers"].length
    assert_equal true, body["begin_loading_imported_customers"]
  end

  test "GET index returns the correct number of imported customers on last page" do
    25.times do |i|
      ImportedCustomer.create!(email: "ic-#{i}@example.com", purchase_date: Time.current, link_id: @product.id, importing_user: @seller)
    end
    get :index, params: { link_id: @product.unique_permalink, page: 1 }
    body = JSON.parse(@response.body)
    assert_equal 5, body["customers"].length
  end

  test "DELETE destroy soft-deletes the imported_customer" do
    ic = ImportedCustomer.create!(email: "del@example.com", purchase_date: Time.current, link_id: @product.id, importing_user: @seller)
    delete :destroy, params: { id: ic.external_id }
    assert_response :success
    body = JSON.parse(@response.body)
    assert body["success"]
    assert ic.reload.deleted_at.present?
  end
end
