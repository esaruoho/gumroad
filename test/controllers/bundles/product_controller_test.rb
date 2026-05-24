# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Bundles::ProductControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    @bundle = links(:bundle_update_products_bundle)
    sign_in_as_seller(@seller)
    @request.headers["X-Inertia"] = "true"
  end

  teardown { restore_protect_against_forgery! }

  test "GET edit renders the Bundles/Product/Edit inertia component" do
    get :edit, params: { bundle_id: @bundle.external_id }
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Bundles/Product/Edit", page["component"]
  end

  test "GET edit raises RecordNotFound for non-existent bundle" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get :edit, params: { bundle_id: "does-not-exist" }
    end
  end
end
