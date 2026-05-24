# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Products::ArchivedControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    @product = links(:named_seller_product)
    sign_in_as_seller(@seller)
    @request.headers["X-Inertia"] = "true"
  end

  teardown { restore_protect_against_forgery! }

  test "GET index redirects to products when no archived products" do
    # `archived` is a flag bit (bit 5, value 16) on Link, not a column. Clear it via SQL.
    archived_bit = Link.flag_mapping["flags"][:archived]
    Link.where(user: @seller).update_all("flags = flags & ~#{archived_bit}")
    get :index
    assert_response :redirect
  end

  test "POST create archives the product and sets purchase_disabled_at" do
    @product.update!(archived: false, purchase_disabled_at: nil)
    post :create, params: { id: @product.unique_permalink }, as: :json
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
    @product.reload
    assert @product.archived?
    refute_nil @product.purchase_disabled_at
  end

  test "DELETE destroy unarchives the product" do
    @product.update!(archived: true)
    delete :destroy, params: { id: @product.unique_permalink }, as: :json
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
    @product.reload
    refute @product.archived?
  end
end
