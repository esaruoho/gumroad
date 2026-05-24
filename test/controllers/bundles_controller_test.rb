# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class BundlesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    @bundle = links(:bundle_update_products_bundle)
    sign_in_as_seller(@admin, @seller)
  end

  teardown { restore_protect_against_forgery! }

  test "GET show redirects to the edit product page" do
    get :show, params: { id: @bundle.external_id }
    assert_redirected_to edit_bundle_product_path(@bundle.external_id)
    assert_response :moved_permanently
  end

  test "GET show returns 404 when bundle doesn't exist" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get :show, params: { id: "" }
    end
  end

  test "GET show returns 404 for membership product" do
    membership = links(:footer_membership_product)
    assert_raises(ActiveRecord::RecordNotFound) do
      get :show, params: { id: membership.external_id }
    end
  end

  test "POST create_from_email creates the bundle and redirects to the edit page" do
    product = links(:basic_user_product)
    product.update_column(:user_id, @seller.id)

    bundle = nil
    Link.bypass_product_creation_limit do
      get :create_from_email, params: {
        type: Product::BundlesMarketing::BEST_SELLING_BUNDLE,
        price: 100,
        products: [product.external_id],
      }
      bundle = Link.where(user: @seller, native_type: Link::NATIVE_TYPE_BUNDLE).order(:id).last
    end
    assert_redirected_to edit_bundle_product_path(bundle.external_id)
    assert_equal "Best Selling Bundle", bundle.name
    assert_equal 100, bundle.price_cents
    assert bundle.is_bundle
    assert bundle.from_bundle_marketing
    assert_equal Link::NATIVE_TYPE_BUNDLE, bundle.native_type
    assert_equal Currency::USD, bundle.price_currency_type
    bp = bundle.bundle_products.first
    assert_equal product, bp.product
    assert_equal 1, bp.quantity
  end
end
