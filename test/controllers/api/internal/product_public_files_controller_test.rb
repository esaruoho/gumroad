# frozen_string_literal: true

require "test_helper"

class Api::Internal::ProductPublicFilesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save! if @seller.external_id.blank?
    sign_in @seller
  end

  test "POST create requires authentication" do
    sign_out @seller
    post :create, params: { product_id: "anything", signed_blob_id: "x" }
    assert_includes [302, 401, 403], @response.status
  end

  test "POST create returns 404 / redirect when the product does not exist for current seller" do
    post :create, params: { product_id: "no-such-product", signed_blob_id: "x" }
    # The controller calls e404 (RoutingError) which propagates in test env.
    assert_includes [302, 404, 422], @response.status
  end
end
